import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/core/Cache/cache_helper.dart';

class LanguageCubit extends Cubit<Locale> {
  static const _cacheKey = 'app_language_code';

  LanguageCubit()
    : super(
        Locale(CacheHelper.getDataString(key: _cacheKey) == 'en' ? 'en' : 'ar'),
      );

  bool get isArabic => state.languageCode == 'ar';

  Future<void> setLanguage(String languageCode) async {
    final normalized = languageCode == 'en' ? 'en' : 'ar';
    if (state.languageCode == normalized) return;
    emit(Locale(normalized));
    await CacheHelper.saveData(key: _cacheKey, value: normalized);
  }

  Future<void> toggleLanguage() => setLanguage(isArabic ? 'en' : 'ar');
}
