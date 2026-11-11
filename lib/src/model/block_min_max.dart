import 'dart:typed_data';

/// Block-aggregated range min/max: query cost O(range/blockSize + 2*blockSize) instead of
/// O(range). Blocks are aligned to absolute indices and built on demand;
/// when a new query touches the built region it extends at both ends, so panned ranges stay cached
/// (16 bytes per 64 bars, about 3% of the series itself). NaN is skipped.
class BlockMinMaxCache {
  static const int blockSize = 64;

  /// On full invalidation, the buffer is also freed if it exceeds this many blocks (about 16k
  /// bars), so viewing large data then switching to small data does not waste memory.
  static const int keepCapacity = 256;

  Float64List _lo = Float64List(0);
  Float64List _hi = Float64List(0);

  /// Built block window `[_validFrom, _validTo)`; both are equal when empty.
  int _validFrom = 0;
  int _validTo = 0;

  /// How many blocks the current buffer can hold.
  int get capacity => _lo.length;

  void invalidateAll() {
    _validFrom = 0;
    _validTo = 0;
    if (_lo.length > keepCapacity) release();
  }

  /// Drops all blocks and frees the buffer; the next query rebuilds on demand.
  void release() {
    _validFrom = 0;
    _validTo = 0;
    _lo = Float64List(0);
    _hi = Float64List(0);
  }

  /// Drops the block containing [index] and all blocks after it.
  void invalidateFrom(int index) {
    final block = index < 0 ? 0 : index ~/ blockSize;
    if (block < _validTo) _validTo = block;
    if (_validTo <= _validFrom) invalidateAll();
  }

  /// Raw (lo, hi) over `[start, end]` (inclusive), clamped to `[0, length)`; (+inf, -inf) if empty.
  (double, double) minMax(
    int start,
    int end,
    int length,
    double Function(int) loOf,
    double Function(int) hiOf,
  ) {
    var lo = double.infinity, hi = double.negativeInfinity;
    // Clamp into locals instead of reassigning parameters: otherwise whether start/end in the
    // following dozens of lines are the inputs or clamped values is only clear from reading the
    // code (parameter_assignments).
    final lowIndex = start < 0 ? 0 : start;
    final highIndex = end >= length ? length - 1 : end;
    if (highIndex < lowIndex) return (lo, hi);

    // Only full blocks count: a partial block in the table would not be invalidated as data grows,
    // and would keep missing the tail.
    final firstBlock = (lowIndex + blockSize - 1) ~/ blockSize;
    final completeBlocks = length ~/ blockSize;
    var endBlock = (highIndex + 1) ~/ blockSize;
    if (endBlock > completeBlocks) endBlock = completeBlocks;

    void scan(int i0, int i1) {
      for (var i = i0; i <= i1; i++) {
        final l = loOf(i), h = hiOf(i);
        if (l < lo) lo = l; // NaN comparisons are always false, so NaN is skipped
        if (h > hi) hi = h;
      }
    }

    if (firstBlock >= endBlock) {
      scan(lowIndex, highIndex); // No full block in the range
      return (lo, hi);
    }

    _ensureBuilt(firstBlock, endBlock, length, loOf, hiOf);
    scan(lowIndex, firstBlock * blockSize - 1);
    for (var k = firstBlock; k < endBlock; k++) {
      final bl = _lo[k - _validFrom], bh = _hi[k - _validFrom];
      if (bl < lo) lo = bl;
      if (bh > hi) hi = bh;
    }
    scan(endBlock * blockSize, highIndex);
    return (lo, hi);
  }

  /// Ensures `[from, to)` is built: if adjacent to the current window, shift and fill only the
  /// ends; otherwise rebuild the whole window (capacity doubles as needed). [length] is only used
  /// to assert that only full blocks are built: the inner loop steps by whole blocks, so a partial
  /// one would read out of bounds.
  void _ensureBuilt(
    int from,
    int to,
    int length,
    double Function(int) loOf,
    double Function(int) hiOf,
  ) {
    assert(
      to <= length ~/ blockSize,
      'BlockMinMaxCache only caches full blocks: to=$to exceeds full block count of length=$length',
    );
    if (from >= _validFrom && to <= _validTo) return;

    final oldFrom = _validFrom, oldTo = _validTo;
    final hasOld = oldTo > oldFrom;
    final overlaps = hasOld && from < oldTo && to > oldFrom;
    final newFrom = overlaps && oldFrom < from ? oldFrom : from;
    final newTo = overlaps && oldTo > to ? oldTo : to;

    var reuse = overlaps;
    if (_lo.length < newTo - newFrom) {
      var cap = _lo.length < 16 ? 16 : _lo.length;
      while (cap < newTo - newFrom) {
        cap *= 2;
      }
      _lo = Float64List(cap);
      _hi = Float64List(cap);
      reuse = false; // Buffer replaced, old blocks lost
    }
    // Register the new window first; _build computes slot offsets from it
    _validFrom = newFrom;
    _validTo = newTo;

    if (!reuse) {
      _build(newFrom, newTo, loOf, hiOf);
      return;
    }
    // Move old blocks to the new offset (newFrom <= oldFrom, so only right shifts; copying
    // backwards does not overwrite)
    final shift = oldFrom - newFrom;
    if (shift > 0) {
      for (var i = oldTo - oldFrom - 1; i >= 0; i--) {
        _lo[i + shift] = _lo[i];
        _hi[i + shift] = _hi[i];
      }
    }
    _build(newFrom, oldFrom, loOf, hiOf); // Left gap
    _build(oldTo, newTo, loOf, hiOf); // Right gap
  }

  /// Builds blocks `[from, to)`; slots are relative to the current window origin [_validFrom].
  void _build(
    int from,
    int to,
    double Function(int) loOf,
    double Function(int) hiOf,
  ) {
    for (var k = from; k < to; k++) {
      var bl = double.infinity, bh = double.negativeInfinity;
      final i1 = k * blockSize + blockSize;
      for (var i = k * blockSize; i < i1; i++) {
        final l = loOf(i), h = hiOf(i);
        if (l < bl) bl = l;
        if (h > bh) bh = h;
      }
      _lo[k - _validFrom] = bl;
      _hi[k - _validFrom] = bh;
    }
  }
}
