import 'package:flutter_najwafth_buyer/core/services/address_suggestion_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AddressSuggestionService service;

  setUp(() => service = AddressSuggestionService());
  tearDown(() => service.dispose());

  group('AddressSuggestionService local suggestions (short queries)', () {
    test('empty query previews popular cities, Paris first', () async {
      final results = await service.search('');
      expect(results, isNotEmpty);
      expect(results.first.primary, 'Paris');
      expect(results.first.fullAddress, 'Paris, 75000, France');
      expect(results.first.isCity, isTrue);
      expect(results.length, lessThanOrEqualTo(8));
    });

    test('single letter surfaces biggest matching cities first', () async {
      final results = await service.search('l');
      expect(results, isNotEmpty);
      // Lyon is the most populous city starting with L.
      expect(results.first.primary, 'Lyon');
      final names = results.map((r) => r.primary).toList();
      expect(names, contains('Lille'));
    });

    test('two letters keeps prefix matches on top', () async {
      final results = await service.search('ma');
      expect(results.first.primary, 'Marseille');
    });

    test('matching is accent-insensitive', () async {
      // "me" should match Metz and also accented Mérignac/Mèze-like names.
      final results = await service.search('me');
      final names = results.map((r) => r.primary).toList();
      expect(names, contains('Metz'));
      expect(names, contains('Mérignac'));
    });

    test('postal-code prefix matches cities', () async {
      final results = await service.search('21');
      final names = results.map((r) => r.primary).toList();
      expect(names, contains('Dijon'));
    });

    test('suggestion parts are consistent', () async {
      final results = await service.search('di');
      final dijon = results.firstWhere((r) => r.primary == 'Dijon');
      expect(dijon.secondary, '21000 · France');
      expect(dijon.fullAddress, 'Dijon, 21000, France');
      expect(dijon.isCity, isTrue);
    });
  });
}
