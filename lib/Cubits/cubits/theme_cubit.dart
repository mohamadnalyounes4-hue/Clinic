import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/core/Cache/cache_helper.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const _cacheKey = 'dark_mode_enabled';

  ThemeCubit()
    : super(
        CacheHelper.getData(key: _cacheKey) == true
            ? ThemeMode.dark
            : ThemeMode.light,
      );

  bool get isDark => state == ThemeMode.dark;

  Future<void> setDarkMode(bool enabled) async {
    emit(enabled ? ThemeMode.dark : ThemeMode.light);
    await CacheHelper.saveData(key: _cacheKey, value: enabled);
  }
}
