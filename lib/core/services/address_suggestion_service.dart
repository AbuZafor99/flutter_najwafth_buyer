import 'dart:async';

import 'package:dio/dio.dart';

import '../utils/french_places.dart';

/// A single address suggestion, split into parts so the UI can render a
/// rich two-line row (headline + locality) like a native places picker.
final class AddressSuggestion {
  const AddressSuggestion({
    required this.primary,
    required this.secondary,
    required this.fullAddress,
    required this.isCity,
    this.street = '',
    this.city = '',
    this.postcode = '',
    this.region = '',
    this.countryIso = 'FR',
  });

  /// Headline — the place itself ("Paris", "8 Boulevard du Port").
  final String primary;

  /// Supporting line — `locality · region · France`.
  final String secondary;

  /// International-format address written into the field on selection,
  /// ordered local → broad: `place, postcode city, region, France`.
  final String fullAddress;

  /// Whether this is a commune (city/town) rather than a street address.
  final bool isCity;

  // ── Structured parts, used to auto-fill the checkout address form ──
  /// Street line (empty for a bare city/town suggestion).
  final String street;
  final String city;
  final String postcode;
  final String region;
  final String countryIso;
}

/// Provides address autocomplete suggestions for anywhere in France.
///
/// Backed by the official, key-free Base Adresse Nationale (BAN) API, which
/// covers every French address, street and commune. Requests are debounced
/// and the previous in-flight request is cancelled on each new keystroke.
/// When the query is too short for the API (< 3 chars) or the network fails,
/// it falls back to a curated, population-ordered local list so suggestions
/// always work.
class AddressSuggestionService {
  AddressSuggestionService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 4),
              receiveTimeout: const Duration(seconds: 4),
            ),
          );

  final Dio _dio;

  static const _endpoint = 'https://api-adresse.data.gouv.fr/search/';
  static const _debounceDelay = Duration(milliseconds: 300);

  /// Maximum number of rows surfaced in the dropdown.
  static const _maxSuggestions = 8;

  /// How many city/town rows may sit above the street-level results.
  static const _maxCities = 4;

  Timer? _debounce;
  CancelToken? _cancelToken;
  Completer<List<AddressSuggestion>>? _pending;

  /// Returns suggestions for [query]: cities and towns first (biggest
  /// places on top), then precise street-level addresses.
  Future<List<AddressSuggestion>> search(String query) {
    final q = query.trim();

    // Supersede any in-flight request so stale results never win.
    _debounce?.cancel();
    _cancelToken?.cancel();
    if (_pending?.isCompleted == false) {
      _pending!.complete(const []);
    }

    // The BAN API requires at least 3 characters; serve short queries (a
    // single letter/word) and the empty focus state from the local list.
    if (q.length < 3) {
      return Future.value(_localMatches(q));
    }

    final completer = Completer<List<AddressSuggestion>>();
    final token = CancelToken();
    _pending = completer;
    _cancelToken = token;

    _debounce = Timer(_debounceDelay, () async {
      try {
        // Two parallel queries: communes (cities/towns) and street-level
        // addresses. Communes lead so a city or small town surfaces first.
        final grouped = await Future.wait([
          _query(q, token, limit: _maxCities + 1, type: 'municipality'),
          _query(q, token, limit: _maxSuggestions),
        ]);

        final merged = <AddressSuggestion>[];
        final seen = <String>{};
        for (final suggestion in [
          ...grouped[0].take(_maxCities),
          ...grouped[1],
        ]) {
          if (seen.add(suggestion.fullAddress.toLowerCase())) {
            merged.add(suggestion);
          }
        }

        if (!completer.isCompleted) {
          completer.complete(
            merged.isNotEmpty
                ? merged.take(_maxSuggestions).toList()
                : _localMatches(q),
          );
        }
      } catch (_) {
        // Network/parse failure or cancellation: fall back to the local list.
        if (!completer.isCompleted) {
          completer.complete(_localMatches(q));
        }
      }
    });

    return completer.future;
  }

  /// Runs a single BAN query, optionally filtered by [type] (e.g.
  /// `municipality` for cities/towns), and maps it to suggestions.
  Future<List<AddressSuggestion>> _query(
    String q,
    CancelToken token, {
    required int limit,
    String? type,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _endpoint,
      queryParameters: {
        'q': q,
        'limit': limit,
        'autocomplete': 1,
        'type': ?type,
      },
      cancelToken: token,
    );
    final features = (response.data?['features'] as List?) ?? const [];
    final props = features
        .map((f) => (f as Map)['properties'])
        .whereType<Map>()
        .toList();

    // For cities/towns, list the biggest place first (e.g. Paris before its
    // arrondissements, a large town before a village with a similar name).
    if (type == 'municipality') {
      props.sort((a, b) {
        final pa = (a['population'] as num?) ?? 0;
        final pb = (b['population'] as num?) ?? 0;
        return pb.compareTo(pa);
      });
    }

    return props.map(_toSuggestion).whereType<AddressSuggestion>().toList();
  }

  /// Maps raw BAN properties to a structured [AddressSuggestion].
  AddressSuggestion? _toSuggestion(Map props) {
    final name = (props['name'] as String?)?.trim();
    final label = (props['label'] as String?)?.trim();
    final primary = (name != null && name.isNotEmpty) ? name : label;
    if (primary == null || primary.isEmpty) {
      return null;
    }

    final postcode = (props['postcode'] as String?)?.trim() ?? '';
    final city = (props['city'] as String?)?.trim() ?? '';
    final region = _regionFromContext(props['context'] as String?) ?? '';
    final isCity = props['type'] == 'municipality';

    // For a commune the headline already is the town, so the locality is
    // just its postcode; for a street it is "postcode city".
    final locality = isCity
        ? postcode
        : [
            if (postcode.isNotEmpty) postcode,
            if (city.isNotEmpty) city,
          ].join(' ');

    final tail = [
      if (locality.isNotEmpty) locality,
      if (region.isNotEmpty) region,
      'France',
    ];

    return AddressSuggestion(
      primary: primary,
      secondary: tail.join(' · '),
      fullAddress: [primary, ...tail].join(', '),
      isCity: isCity,
      // A commune has no street; a street result exposes its own name.
      street: isCity ? '' : primary,
      city: city,
      postcode: postcode,
      region: region,
      countryIso: 'FR',
    );
  }

  /// The region is the last segment of the BAN `context`
  /// (e.g. `75, Paris, Île-de-France` → `Île-de-France`).
  String? _regionFromContext(String? context) {
    if (context == null || context.isEmpty) {
      return null;
    }
    final segments = context
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return segments.isEmpty ? null : segments.last;
  }

  /// Offline ranking: name/postal-code prefix matches first (so a single
  /// letter surfaces the biggest matching cities), then substring matches.
  /// Matching is accent-insensitive, so `meze` finds `Mèze`.
  /// [kFrenchPlaces] is population-ordered, keeping popular places on top.
  List<AddressSuggestion> _localMatches(String query) {
    AddressSuggestion fmt(FrenchPlace p) => AddressSuggestion(
      primary: p.city,
      secondary: '${p.postalCode} · France',
      fullAddress: '${p.city}, ${p.postalCode}, France',
      isCity: true,
      city: p.city,
      postcode: p.postalCode,
      countryIso: 'FR',
    );

    final q = _fold(query.trim());
    if (q.isEmpty) {
      return kFrenchPlaces.take(_maxSuggestions).map(fmt).toList();
    }
    final starts = <AddressSuggestion>[];
    final contains = <AddressSuggestion>[];
    for (final place in kFrenchPlaces) {
      final city = _fold(place.city);
      if (city.startsWith(q) || place.postalCode.startsWith(q)) {
        starts.add(fmt(place));
      } else if (city.contains(q)) {
        contains.add(fmt(place));
      }
    }
    return [...starts, ...contains].take(_maxSuggestions).toList();
  }

  /// Lowercases and strips French diacritics for forgiving comparisons.
  String _fold(String value) {
    const replacements = {
      'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'î': 'i', 'ï': 'i', 'í': 'i',
      'ô': 'o', 'ö': 'o', 'ó': 'o',
      'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
      'ç': 'c', 'ÿ': 'y', 'ñ': 'n',
      'œ': 'oe', 'æ': 'ae',
      '’': "'", '-': ' ',
    };
    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(replacements[char] ?? char);
    }
    return buffer.toString();
  }

  void dispose() {
    _debounce?.cancel();
    _cancelToken?.cancel();
  }
}
