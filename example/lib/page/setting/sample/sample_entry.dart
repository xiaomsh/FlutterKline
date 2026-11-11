import 'package:flutter/widgets.dart';

import '../../../l10n/l10n.dart';

enum SampleCategory {
  data,
  main,
  coordinates,
  indicators,
  interaction,
  appearance,
  extensions,
  stocks,
  pro,
  storage;

  String get title => switch (this) {
    data => S.current.sampleCategoryData,
    main => S.current.sampleCategoryMain,
    coordinates => S.current.sampleCategoryCoordinates,
    indicators => S.current.sampleCategoryIndicators,
    interaction => S.current.sampleCategoryInteraction,
    appearance => S.current.sampleCategoryAppearance,
    extensions => S.current.sampleCategoryExtensions,
    stocks => S.current.sampleCategoryStocks,
    pro => S.current.sampleCategoryPro,
    storage => S.current.sampleCategoryStorage,
  };
}

/// One item of the sample catalog: each is an independent sample (own controller, chart and
/// settings panel) that does not affect the others.
class SampleEntry {
  const SampleEntry({
    required this.id,
    required this.category,
    required this._title,
    required this.builder,
    this._description,
    this._searchTerms,
    this.keywords = const [],
  }) : locked = false;

  /// Placeholder of a full-version feature in the free version: listed in the menu as usual,
  /// tapping it prompts to unlock.
  const SampleEntry.locked({
    required this.id,
    required this.category,
    required this._title,
    this.keywords = const [],
  }) : _description = null,
       _searchTerms = null,
       locked = true,
       builder = null;

  /// Route `/setting/<id>`, globally unique.
  final String id;
  final SampleCategory category;
  final String Function() _title;
  final String Function()? _description;
  final String Function()? _searchTerms;

  /// API names used for search.
  final List<String> keywords;
  final bool locked;
  final Widget Function()? builder;

  String get title => _title();

  String get description => locked ? S.current.sampleLockedDescription : _description?.call() ?? '';

  bool matches(String query) => '$title $id ${keywords.join(' ')} ${_searchTerms?.call() ?? ''}'
      .toLowerCase()
      .contains(query.toLowerCase().trim());
}
