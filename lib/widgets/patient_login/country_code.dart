class CountryCode {
  final String name;
  final String code;

  const CountryCode({required this.name, required this.code});
}

class CountryCodes {
  const CountryCodes._();

  static const List<CountryCode> defaultCodes = [
    CountryCode(name: 'سوريا', code: '+963'),
    CountryCode(name: 'تركيا', code: '+90'),
    CountryCode(name: 'السعودية', code: '+966'),
    CountryCode(name: 'الإمارات', code: '+971'),
    CountryCode(name: 'الأردن', code: '+962'),
    CountryCode(name: 'مصر', code: '+20'),
  ];
}
