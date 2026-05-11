import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/base_screen.dart';

/// Country model
class Country {
  final String name;
  final String flag;
  final String code;

  const Country({required this.name, required this.flag, required this.code});
}

/// List of countries
final List<Country> countries = [
  const Country(name: 'الإمارات العربية المتحدة', flag: '🇦🇪', code: '+971'),
  const Country(name: 'المملكة العربية السعودية', flag: '🇸🇦', code: '+966'),
  const Country(name: 'مصر', flag: '🇪🇬', code: '+20'),
  const Country(name: 'الأردن', flag: '🇯🇴', code: '+962'),
  const Country(name: 'لبنان', flag: '🇱🇧', code: '+961'),
  const Country(name: 'سوريا', flag: '🇸🇾', code: '+963'),
  const Country(name: 'العراق', flag: '🇮🇶', code: '+964'),
  const Country(name: 'الكويت', flag: '🇰🇼', code: '+965'),
  const Country(name: 'قطر', flag: '🇶🇦', code: '+974'),
  const Country(name: 'البحرين', flag: '🇧🇭', code: '+973'),
  const Country(name: 'عمان', flag: '🇴🇲', code: '+968'),
  const Country(name: 'الجزائر', flag: '🇩🇿', code: '+213'),
  const Country(name: 'المغرب', flag: '🇲🇦', code: '+212'),
  const Country(name: 'تونس', flag: '🇹🇳', code: '+216'),
  const Country(name: 'ليبيا', flag: '🇱🇾', code: '+218'),
  const Country(name: 'السودان', flag: '🇸🇩', code: '+249'),
  const Country(name: 'تركيا', flag: '🇹🇷', code: '+90'),
  const Country(name: 'الولايات المتحدة', flag: '🇺🇸', code: '+1'),
  const Country(name: 'المملكة المتحدة', flag: '🇬🇧', code: '+44'),
  const Country(name: 'فرنسا', flag: '🇫🇷', code: '+33'),
  const Country(name: 'ألمانيا', flag: '🇩🇪', code: '+49'),
  const Country(name: 'إيطاليا', flag: '🇮🇹', code: '+39'),
  const Country(name: 'إسبانيا', flag: '🇪🇸', code: '+34'),
  const Country(name: 'كندا', flag: '🇨🇦', code: '+1'),
  const Country(name: 'أستراليا', flag: '🇦🇺', code: '+61'),
  const Country(name: 'الصين', flag: '🇨🇳', code: '+86'),
  const Country(name: 'اليابان', flag: '🇯🇵', code: '+81'),
  const Country(name: 'الهند', flag: '🇮🇳', code: '+91'),
  const Country(name: 'باكستان', flag: '🇵🇰', code: '+92'),
];

/// Login Screen with sky blue gradient background
/// Inherits from BaseScreen for consistent scaffold structure
class LoginScreen extends BaseScreen {
  const LoginScreen({super.key});

  @override
  Widget body(BuildContext context) {
    return const _LoginScreenContent();
  }
}

class _LoginScreenContent extends StatefulWidget {
  const _LoginScreenContent();

  @override
  State<_LoginScreenContent> createState() => _LoginScreenContentState();
}

class _LoginScreenContentState extends State<_LoginScreenContent> {
  Country selectedCountry = countries[0]; // Default UAE
  bool _obscurePassword = true;

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CountryPickerBottomSheet(
        onSelect: (country) {
          setState(() {
            selectedCountry = country;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Sky blue gradient background
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF87CEEB), // Sky blue
                  Color(0xFF4A90E2), // Deeper blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Logo
                Image.asset(
                  'assets/images/logo1.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 40),
                // Title
                Text(
                  'تسجيل الدخول',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                // Phone input card (glass style)
                _buildGlassCard(
                  child: Row(
                    children: [
                      // Country selector
                      GestureDetector(
                        onTap: _showCountryPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                selectedCountry.flag,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                selectedCountry.code,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Phone input
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'ادخل الرقم بدون الرمز الدولي',
                            hintStyle: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Password input card (glass style)
                _buildGlassCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'كلمة المرور',
                            hintStyle: TextStyle(color: Colors.black54),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'تسجيل الدخول',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ليس لديك حساب؟',
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'إنشاء حساب',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build glass-style cards
  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.15),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }
}

/// Country Picker Bottom Sheet
class _CountryPickerBottomSheet extends StatefulWidget {
  final Function(Country) onSelect;

  const _CountryPickerBottomSheet({required this.onSelect});

  @override
  State<_CountryPickerBottomSheet> createState() =>
      _CountryPickerBottomSheetState();
}

class _CountryPickerBottomSheetState extends State<_CountryPickerBottomSheet> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => searchQuery = '');
    _searchFocusNode.requestFocus();
  }

  List<Country> get filteredCountries {
    if (searchQuery.trim().isEmpty) return countries;

    final query = searchQuery.toLowerCase().trim();
    final normalizedQuery = _normalizeArabic(query);

    return countries.where((country) {
      // Search by country name (Arabic)
      final normalizedName = _normalizeArabic(country.name.toLowerCase());
      if (normalizedName.contains(normalizedQuery)) return true;

      // Search by dial code
      if (country.code.contains(query.replaceAll('+', ''))) return true;
      if (country.code.contains(query)) return true;

      // Search by flag emoji (if user types the flag)
      if (country.flag.contains(query)) return true;

      return false;
    }).toList();
  }

  // Normalize Arabic text for better search
  String _normalizeArabic(String text) {
    return text
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'اختر الدولة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // Search field with clear button
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (value) => setState(() => searchQuery = value),
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText:
                        'ابحث عن الدولة أو الرمز (مثال: +971 أو الإمارات)',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                // Search results count
                if (searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${filteredCountries.length} نتيجة',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Countries list
          Expanded(
            child: filteredCountries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد نتائج',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _clearSearch,
                          child: const Text('مسح البحث'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredCountries.length,
                    itemBuilder: (context, index) {
                      final country = filteredCountries[index];
                      return ListTile(
                        leading: Text(
                          country.flag,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(country.name),
                        trailing: Text(
                          country.code,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () => widget.onSelect(country),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
