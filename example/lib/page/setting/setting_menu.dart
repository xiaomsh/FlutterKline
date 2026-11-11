import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'sample/sample_entry.dart';

/// Left menu: grouped by category, searchable by title, id and API name.
class SettingMenu extends StatefulWidget {
  const SettingMenu({
    super.key,
    required this.entries,
    required this.selected,
    required this.onSelect,
  });
  final List<SampleEntry> entries;
  final String? selected;
  final ValueChanged<SampleEntry> onSelect;

  @override
  State<SettingMenu> createState() => _SettingMenuState();
}

/// Switching samples changes the route (each sample has its own URL) and rebuilds the whole menu;
/// scroll offset, search query and collapsed state are kept here and reused after the rebuild.
class _MenuMemory {
  static double offset = 0;
  static String query = '';
  static final Set<SampleCategory> collapsed = {};
  static bool restored = false;
}

/// Clears the remembered scroll offset, search query and collapsed state (used between tests).
@visibleForTesting
void resetSettingMenuMemory() {
  _MenuMemory.offset = 0;
  _MenuMemory.query = '';
  _MenuMemory.restored = false;
  _MenuMemory.collapsed.clear();
}

class _SettingMenuState extends State<SettingMenu> {
  String query = _MenuMemory.query;
  late final _search = TextEditingController(text: query);
  late final ScrollController _scroll = ScrollController(initialScrollOffset: _MenuMemory.offset)
    ..addListener(() => _MenuMemory.offset = _scroll.offset);
  final _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // On first open (e.g. opening a sample URL directly) scroll the selected item into view
    if (!_MenuMemory.restored) {
      _MenuMemory.restored = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _selectedKey.currentContext;
        if (ctx != null && ctx.mounted) Scrollable.ensureVisible(ctx, alignment: 0.3);
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
    child: Column(
      key: const ValueKey('setting-menu'),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: S.current.settingMenuSearchHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) => setState(() => query = _MenuMemory.query = value),
          ),
        ),
        Expanded(
          child: ListView(
            controller: _scroll,
            children: [
              for (final category in SampleCategory.values)
                if (widget.entries.any((e) => e.category == category && e.matches(query)))
                  ExpansionTile(
                    key: PageStorageKey((category, query)),
                    initiallyExpanded: !_MenuMemory.collapsed.contains(category),
                    onExpansionChanged: (open) => open
                        ? _MenuMemory.collapsed.remove(category)
                        : _MenuMemory.collapsed.add(category),
                    title: Text(category.title),
                    children: [
                      for (final entry in widget.entries)
                        if (entry.category == category && entry.matches(query))
                          KeyedSubtree(
                            key: entry.id == widget.selected ? _selectedKey : null,
                            child: ListTile(
                              key: ValueKey('menu-${entry.id}'),
                              dense: true,
                              selected: entry.id == widget.selected,
                              selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
                              title: Text(entry.title),
                              trailing: entry.locked
                                  ? const Icon(Icons.lock_outline, size: 16)
                                  : null,
                              onTap: () => widget.onSelect(entry),
                            ),
                          ),
                    ],
                  ),
            ],
          ),
        ),
      ],
    ),
  );
}
