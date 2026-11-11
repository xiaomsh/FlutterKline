// Archives frame times from integration_test/chart_perf_test.dart to benchmark/results/ and
// compares them with the previous run.
// Env vars: PERF_LABEL device name (used in the file name); PERF_MAX_P90_MS fails the run if any
// scene's 90th-percentile build or raster time exceeds it.
import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

const _keys = [
  'average_frame_build_time_millis',
  '90th_percentile_frame_build_time_millis',
  'worst_frame_build_time_millis',
  'average_frame_rasterizer_time_millis',
  '90th_percentile_frame_rasterizer_time_millis',
  'worst_frame_rasterizer_time_millis',
  'missed_frame_build_budget_count',
  'missed_frame_rasterizer_budget_count',
  'frame_count',
];

const _scenes = ['pan', 'zoom', 'ticks'];

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    final dir = Directory('benchmark/results')..createSync(recursive: true);
    final previous = _latest(dir);
    final label = (Platform.environment['PERF_LABEL'] ?? 'device').replaceAll(
      RegExp(r'[^\w.-]'),
      '_',
    );
    final stamp = DateTime.now().toIso8601String().substring(0, 19).replaceAll(':', '');
    final out = {
      'label': label,
      'time': DateTime.now().toIso8601String(),
      'meta': data['meta'],
      for (final s in _scenes)
        if (data[s] is Map) s: {for (final k in _keys) k: (data[s] as Map)[k]},
    };
    final file = File('${dir.path}/$stamp-$label.json');
    file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(out));
    stdout.writeln(
      'Archived ${file.path}${previous == null ? '' : ', compared with ${previous.path}'}',
    );
    final prev = previous == null
        ? null
        : jsonDecode(previous.readAsStringSync()) as Map<String, dynamic>;
    for (final s in _scenes) {
      final cur = out[s] as Map?;
      if (cur == null) continue;
      stdout.writeln('[$s]');
      for (final k in _keys) {
        final v = cur[k] as num?;
        final p = (prev?[s] as Map?)?[k] as num?;
        final delta = v == null || p == null || p == 0
            ? ''
            : '  (${v >= p ? '+' : ''}${((v - p) / p * 100).toStringAsFixed(1)}%)';
        stdout.writeln('  ${k.padRight(46)} ${v?.toStringAsFixed(2) ?? '-'}$delta');
      }
    }
    final limit = double.tryParse(Platform.environment['PERF_MAX_P90_MS'] ?? '');
    if (limit != null) {
      for (final s in _scenes) {
        final cur = out[s] as Map?;
        for (final k in [
          '90th_percentile_frame_build_time_millis',
          '90th_percentile_frame_rasterizer_time_millis',
        ]) {
          final v = cur?[k] as num?;
          if (v != null && v > limit) {
            stderr.writeln('$s.$k = $v ms, exceeds $limit ms');
            exitCode = 1;
          }
        }
      }
    }
  },
);

File? _latest(Directory dir) {
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return files.isEmpty ? null : files.last;
}
