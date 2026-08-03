/// A single dialing-code entry used by the phone-number country picker.
final class CountryCode {
  const CountryCode({
    required this.name,
    required this.flag,
    required this.dialCode,
    required this.iso,
    this.minDigits = 6,
    this.maxDigits = 15,
  });

  final String name;

  /// Emoji flag rendered in the picker and the selected pill.
  final String flag;

  /// International dialing prefix, e.g. `+33`.
  final String dialCode;

  /// ISO 3166-1 alpha-2 code, used for stable identity.
  final String iso;

  /// Expected national number length (digits, excluding the dial code).
  final int minDigits;
  final int maxDigits;

  /// Text matched against the search query in the picker.
  String get searchable => '$name $dialCode $iso'.toLowerCase();
}

/// Curated list of countries, ordered with the app's primary markets first.
const List<CountryCode> kCountryCodes = [
  CountryCode(
    name: 'France',
    flag: '🇫🇷',
    dialCode: '+33',
    iso: 'FR',
    minDigits: 9,
    maxDigits: 9,
  ),
  CountryCode(
    name: 'Belgium',
    flag: '🇧🇪',
    dialCode: '+32',
    iso: 'BE',
    minDigits: 8,
    maxDigits: 9,
  ),
  CountryCode(
    name: 'Switzerland',
    flag: '🇨🇭',
    dialCode: '+41',
    iso: 'CH',
    minDigits: 9,
    maxDigits: 9,
  ),
  CountryCode(
    name: 'Luxembourg',
    flag: '🇱🇺',
    dialCode: '+352',
    iso: 'LU',
    minDigits: 8,
    maxDigits: 9,
  ),
  CountryCode(
    name: 'United Kingdom',
    flag: '🇬🇧',
    dialCode: '+44',
    iso: 'GB',
    minDigits: 10,
    maxDigits: 10,
  ),
  CountryCode(
    name: 'Germany',
    flag: '🇩🇪',
    dialCode: '+49',
    iso: 'DE',
    minDigits: 10,
    maxDigits: 11,
  ),
  CountryCode(
    name: 'Spain',
    flag: '🇪🇸',
    dialCode: '+34',
    iso: 'ES',
    minDigits: 9,
    maxDigits: 9,
  ),
  CountryCode(
    name: 'Italy',
    flag: '🇮🇹',
    dialCode: '+39',
    iso: 'IT',
    minDigits: 9,
    maxDigits: 10,
  ),
  CountryCode(
    name: 'Netherlands',
    flag: '🇳🇱',
    dialCode: '+31',
    iso: 'NL',
    minDigits: 9,
    maxDigits: 9,
  ),
  CountryCode(
    name: 'Portugal',
    flag: '🇵🇹',
    dialCode: '+351',
    iso: 'PT',
    minDigits: 9,
    maxDigits: 9,
  ),
  CountryCode(
    name: 'Ireland',
    flag: '🇮🇪',
    dialCode: '+353',
    iso: 'IE',
    minDigits: 9,
    maxDigits: 9,
  ),
  CountryCode(
    name: 'United States',
    flag: '🇺🇸',
    dialCode: '+1',
    iso: 'US',
    minDigits: 10,
    maxDigits: 10,
  ),
  CountryCode(
    name: 'Canada',
    flag: '🇨🇦',
    dialCode: '+1',
    iso: 'CA',
    minDigits: 10,
    maxDigits: 10,
  ),
  CountryCode(
    name: 'Morocco',
    flag: '🇲🇦',
    dialCode: '+212',
    iso: 'MA',
    minDigits: 9,
    maxDigits: 9,
  ),
  CountryCode(
    name: 'Algeria',
    flag: '🇩🇿',
    dialCode: '+213',
    iso: 'DZ',
    minDigits: 9,
    maxDigits: 9,
  ),
  CountryCode(
    name: 'Tunisia',
    flag: '🇹🇳',
    dialCode: '+216',
    iso: 'TN',
    minDigits: 8,
    maxDigits: 8,
  ),
  CountryCode(
    name: 'United Arab Emirates',
    flag: '🇦🇪',
    dialCode: '+971',
    iso: 'AE',
    minDigits: 9,
    maxDigits: 9,
  ),
  CountryCode(
    name: 'Saudi Arabia',
    flag: '🇸🇦',
    dialCode: '+966',
    iso: 'SA',
    minDigits: 9,
    maxDigits: 9,
  ),
];

/// Default selection for the picker — the app's home market.
CountryCode get kDefaultCountryCode => kCountryCodes.first;
