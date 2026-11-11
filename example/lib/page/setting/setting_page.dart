import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../l10n/l10n.dart';
import '../../widget/pro_lock.dart';
import 'sample/sample_entry.dart';
import 'sample/sample_layout.dart';
import 'sample_list.dart';
import 'setting_menu.dart';

/// Brightness of the sample catalog, kept across pages.
final settingDark = ValueNotifier(false);

/// Sample catalog shell: menu on the left, current sample on the right. Samples are independent
/// and rebuilt on switch.
class SettingPage extends StatefulWidget {
  const SettingPage({super.key, this.entryId});
  final String? entryId;

  static const defaultEntry = 'data-limit';

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final _scaffold = GlobalKey<ScaffoldState>();
  late final List<SampleEntry> _entries = allSamples();
  late String _selected = widget.entryId ?? SettingPage.defaultEntry;
  int _revision = 0;

  void _select(SampleEntry entry) {
    if (entry.locked) {
      showProLock();
      return;
    }
    if (_scaffold.currentState?.isDrawerOpen ?? false) Navigator.of(context).pop();
    if (entry.id == _selected) return;
    if (Get.key.currentState != null) {
      // Each sample has its own URL that can be opened or shared directly on the web
      Get.offNamed<void>('/setting/${entry.id}');
    } else {
      setState(() => _selected = entry.id);
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: settingDark,
    builder: (context, dark, _) => Theme(
      data: dark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true),
      child: LayoutBuilder(builder: (context, c) => _scaffoldFor(context, dark, c.maxWidth < 700)),
    ),
  );

  Widget _scaffoldFor(BuildContext context, bool dark, bool mobile) {
    final entry = _entries.where((e) => e.id == _selected).firstOrNull;
    Widget menu() => SettingMenu(entries: _entries, selected: _selected, onSelect: _select);
    return Scaffold(
      key: _scaffold,
      appBar: AppBar(
        title: Text(mobile && entry != null ? entry.title : S.current.settingPageTitle),
        actions: [
          IconButton(
            tooltip: dark ? S.current.settingLightMode : S.current.settingDarkMode,
            icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => settingDark.value = !dark,
          ),
        ],
      ),
      drawer: mobile ? Drawer(child: SafeArea(child: menu())) : null,
      body: Row(
        children: [
          if (!mobile) ...[
            SizedBox(width: 232, child: menu()),
            const VerticalDivider(width: 1),
          ],
          Expanded(
            child: entry == null || entry.locked
                ? Center(
                    child: Text(
                      entry == null
                          ? S.current.settingSampleNotFound
                          : S.current.sampleLockedDescription,
                    ),
                  )
                : SampleScope(
                    entry: entry,
                    onReset: () => setState(() => _revision++),
                    child: KeyedSubtree(
                      key: ValueKey('${entry.id}#$_revision'),
                      child: entry.builder!(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
