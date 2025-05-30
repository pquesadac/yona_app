import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'isDarkMode';
  static final List<VoidCallback> _listeners = [];
  
  static Future<bool> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? true; 
  }
  
  static Future<void> setTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
    
    for (final listener in _listeners) {
      listener();
    }
  }
  
  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }
  
  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
  
  static void clearListeners() {
    _listeners.clear();
  }
}