import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'translation_util/translation_service.dart';

enum LevelIndicatorStyle { BUBBLE, CROSSHAIR }
enum BearingType { MAGNETIC, GEOGRAPHIC }
enum ClinometerStyle { RIDGE, FLAT }
// Decimal Degrees, Compact Decimal Degrees, Decimal Minutes, Degrees Minutes Seconds,
enum CoordinatesDisplayFormat { DD, SDD, DMM, DMS }

class SettingsProvider extends ChangeNotifier {
  SharedPreferences? _prefs;

  // Variables
  bool _isDarkMode = false;
  String _language = "en";
  LevelIndicatorStyle _levelIndicatorStyle = LevelIndicatorStyle.BUBBLE;
  BearingType _bearingType = BearingType.MAGNETIC;
  ClinometerStyle _clinometerStyle = ClinometerStyle.RIDGE;
  bool _isLeftHanded = false;
  CoordinatesDisplayFormat _coordDisplayFormat = CoordinatesDisplayFormat.DMM;

  // Getters
  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  LevelIndicatorStyle get levelIndicatorStyle => _levelIndicatorStyle;
  BearingType get bearingType => _bearingType;
  ClinometerStyle get clinometerStyle => _clinometerStyle;
  bool get isLeftHanded => _isLeftHanded;
  CoordinatesDisplayFormat get coordDisplayFormat => _coordDisplayFormat;


  // Load all values from SharedPreferences
  Future<void> loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    // darkMode
    _isDarkMode = _prefs?.getBool('darkMode') ?? false;

    // language
    _language = _prefs?.getString('language') ?? "fr";
    TranslationService.instance.setLanguage(_language);

    // levelIndicatorStyle
    String? stored = _prefs?.getString('levelIndicatorStyle');
    _levelIndicatorStyle = LevelIndicatorStyle.values.firstWhere(
      (e) => e.name == stored,
      orElse: () => LevelIndicatorStyle.BUBBLE,
    );

    // bearingType
    stored = _prefs?.getString('bearingType');
    _bearingType = BearingType.values.firstWhere(
          (e) => e.name == stored,
      orElse: () => BearingType.MAGNETIC,
    );

    // clinometerStyle
    stored = _prefs?.getString('clinometerStyle');
    _clinometerStyle = ClinometerStyle.values.firstWhere(
          (e) => e.name == stored,
      orElse: () => ClinometerStyle.RIDGE,
    );

    // leftHanded
    _isLeftHanded = _prefs?.getBool('leftHanded') ?? false;

    // geo coordinates format
    stored = _prefs?.getString('coordinatesDisplayFormat');
    _coordDisplayFormat = CoordinatesDisplayFormat.values.firstWhere(
          (e) => e.name == stored,
      orElse: () => CoordinatesDisplayFormat.DMM,
    );

    notifyListeners();
  }


  // Setters

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _prefs?.setBool('darkMode', value);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    await _prefs?.setString('language', value);
    TranslationService.instance.setLanguage(_language);
    notifyListeners();
  }

  Future<void> setLevelIndicator(LevelIndicatorStyle value) async {
    _levelIndicatorStyle = value;
    await _prefs?.setString('levelIndicatorStyle', value.name);
    notifyListeners();
  }

  Future<void> setBearingType(BearingType value) async {
    _bearingType = value;
    await _prefs?.setString('bearingType', value.name);
    notifyListeners();
  }

  Future<void> setClinometerStyle(ClinometerStyle value) async {
    _clinometerStyle = value;
    await _prefs?.setString('clinometerStyle', value.name);
    notifyListeners();
  }

  Future<void> setLeftHanded(bool value) async {
    _isLeftHanded = value;
    await _prefs?.setBool('leftHanded', value);
    notifyListeners();
  }

  Future<void> setCoordDisplayFormat(CoordinatesDisplayFormat value) async {
    _coordDisplayFormat = value;
    await _prefs?.setString('coordinatesDisplayFormat', value.name);
    notifyListeners();
  }
}