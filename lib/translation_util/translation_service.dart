import 'package:flutter/material.dart';

class TranslationService extends ChangeNotifier {
  // Singleton
  static final TranslationService instance = TranslationService._();
  TranslationService._();

  String _currentLang = 'fr';
  String get currentLang => _currentLang;

  // All translations in one place. Rework into having external files if it ever gets too much.
  final Map<String, Map<String, String>> _translations = {
    // ***                            ENGLISH                            *** //


    'en': {
      // main.dart
      'app_title' : 'GeoMeasure',

      // home_screen_widget.dart
      'home_app_title' : 'GeoMeasure',
      'home_settings' : 'Settings',
      'home_welcome' : 'Welcome back',
      'home_welcome_2' : 'What would you like to do?',
      'home_start' : 'Start New Session',
      'home_start_2' : 'Begin a new measurement session',
      'home_view_session' : 'View Past Sessions',
      'home_view_session_2' : 'Browse and review your measurements',
      'home_continue_session' : 'Continue Last Session',
      'home_continue_session_2' : 'Pick up where you left off',
      'home_last_session' : 'Last session: ',
      'home_last_session_date' : 'Date: ',
      'home_last_session_measurements' : 'Measurements: ',

      // settings_widget.dart
      'settings_checking' : 'Checking...',
      'settings_title' : 'Settings',
      'settings_theme' : 'Theme',
      'settings_language' : 'Language',
      'settings_left_handed' : 'Left-Handed Mode',
      'settings_left_handed_2' : 'Defaults the dip direction to be (counter)clockwise to the measured bearing. '
          'You can always change it manually when taking a measurement.',
      'settings_bearing_type' : 'Bearing Type',
      'settings_bearing_type_2' : 'Magnetic or True North',
      'settings_magnetic' : 'Magnetic',
      'settings_geographic' : 'True (Geographic)',
      'settings_bearing_type_warning' : 'Warning: Geographic bearing will default to magnetic if geolocation permission is not granted.',
      'settings_level_style' : 'Level Indicator Style',
      'settings_level_style_2' : 'Choose visual style for level indicator on compass',
      'settings_bubble' : 'Bubble',
      'settings_crosshair' : 'Crosshair',
      'settings_inclino_style' : 'Clinometer Style',
      'settings_inclino_style_2' : 'Hold the phone\'s ridge, or the phone flat against the surface to measure inclination.',
      'settings_ridge' : 'Ridge',
      'settings_flat' : 'Flat',
      'settings_coord_style' : 'Coordinates Format',
      'settings_coord_style_2' : 'How GPS coordinates are displayed',
      'settings_geoloc_status' : 'Geolocation Status:',
      'settings_geoloc_request' : 'Set Geolocation Permission',
      'settings_permission_previously_denied' : 'Permission was previously permanently denied. You can change this by accessing your phone\'s settings.',
      'settings_location_disabled' : '❌ Location services disabled',
      'settings_location_denied' : '⚠️ Location permission not granted',
      'settings_location_denied_forever' : '🚫 Location permission permanently denied',
      'settings_location_granted' : '✅ Location permission granted',
      'settings_location_getting' : '\n Getting location...',

      // geo_measurement_widget.dart
      'measure_add_measure' : 'Add a measure',
      'measure_bearing' : 'Bearing',
      'measure_inclination' : 'Inclination',
      'measure_direction' : 'Direction',
      'measure_final_save' : 'Final save',
      'measure_no_compass_data' : 'No compass data',
      'measure_bearing_heading' : 'Bearing / Heading',
      'measure_bearing_heading_2' : '(hold phone flat for best accuracy)',
      'measure_slope_angle' : 'Slope angle',
      'measure_hold_flat' : '(press phone flat against slope)',
      'measure_hold_ridge' : '(press phone\'s ridge against slope)',
      'measure_dip_direction' : 'Dip direction',
      'measure_missing_bearing' : 'Missing strike bearing information. Make sure to first save a bearing in the "Bearing" tab.',
      'measure_save' : 'Save',
      'measure_cancel' : 'Cancel',
      'measure_edit' : 'Edit',
      'measure_geoloc_unavailable' : 'Geolocation is either unavailable or permission hasn\'t been granted.',
      'measure_notes' : 'Notes:',
      'measure_add_notes' : 'Add notes...',
      'measure_no_notes' : 'No notes',
      'measure_save_measure' : 'Save Measurement',
      'measure_saving' : 'Saving...',
      'measure_saved' : 'Measurement saved!',

      // geo_measurement_summary_util.dart
      'util_unnamed_measure' : 'Unnamed measure',
      'util_edit' : 'Edit',
      'util_gps_loc' : 'GPS Location',
      'util_latitude' : 'Latitude',
      'util_longitude' : 'Longitude',
      'util_comp_bearing' : 'Compass Bearing',
      'util_bearing' : 'Bearing',
      'util_orientation' : 'Orientation',
      'util_pitch' : 'Pitch (angle to horizontal)',
      'util_direction' : 'Direction',
      'util_delete' : 'Delete',
      'util_east_oriented' : 'East-oriented',
      'util_west_oriented' : 'West-oriented',
      'util_north_oriented' : 'North-oriented',
      'util_south_oriented' : 'South-oriented',

      // geo_measurement_provider.dart
      'measureP_point' : 'Point',
      'measureP_measure' : 'Measure',

      // measurement_summary.dart
      'measureS_BEARING' : 'BEARING',
      'measureS_DIP' : 'DIP',
      'measureS_COORD' : 'COORDINATES',
      'measureS_coord_not_avail' : 'Coordinates not available',

      // generic_value_save_button.dart
      'saveBtn_save' : 'Save value',

      // dip_direction_painter.dart
      'painter_strike_warning' : 'Strike is roughly E–W. Select the dip side:',
      'painter_SOUTH' : 'SOUTH',
      'painter_WEST' : 'WEST',
      'painter_NORTH' : 'NORTH',
      'painter_EAST' : 'EAST',
      'painter_EAST_WEST' : 'EAST/WEST',
      'painter_NORTH_SOUTH' : 'NORTH/SOUTH',

      // session_widget.dart
      'session_details' : 'Session Details',
      'session_not_found' : 'Session not found.',
      'session_measurements' : 'Measurements',
      'session_add' : 'Add',
      'session_no_measure' : 'No measurements yet.\nTap "Add" to create one.',
      'session_delete_Measurement' : 'Delete Measurement',
      'session_delete_measurement' : 'Delete measurement',
      'session_cancel' : 'Cancel',
      'session_delete' : 'Delete',
      'session_save' : 'Save',
      'session_edit' : 'Edit',
      'session_sessionId' : 'Session ID',
      'session_created' : 'Created',
      'session_last_modif' : 'Last Modified',
      'session_notes' : 'Notes:',
      'session_add_notes' : 'Add notes about this session...',
      'session_no_notes' : 'No notes',
      'session_saved' : 'Session info saved',

      // session_list_widget.dart
      'session_sessions' : 'Sessions',
      'session_new_session' : 'Start New Session',
      'session_new_session_2' : 'Begin a new measurement session',
      'session_list_created' : 'Created:',
      'session_list_last_modified' : 'Last modified:',
      'session_list_measurements' : 'measurements',
      'session_list_measurement' : 'measurement',
    },


    // ***                            FRANCAIS                            *** //


    'fr': {
      // main.dart
      'app_title' : 'GeoMesure',

      // home_screen_widget.dart
      'home_app_title' : 'GeoMesure',
      'home_welcome' : 'Bienvenue',
      'home_welcome_2' : 'Que fait-on aujourd\'hui?',
      'home_start' : 'Nouvelle Session',
      'home_start_2' : 'Démarrer une nouvelle session de mesures',
      'home_view_session' : 'Sessions Précédentes',
      'home_view_session_2' : 'Consulter vos précédentes sessions et mesures',
      'home_continue_session' : 'Dernière Session',
      'home_continue_session_2' : 'Ajouter des mesures à la dernière session',
      'home_last_session' : 'Dernière sessions: ',
      'home_last_session_date' : 'Date: ',
      'home_last_session_measurements' : 'Mesures: ',

      // settings_widget.dart
      'settings_checking' : 'Chargement...',
      'settings_title' : 'Paramètres',
      'settings_theme' : 'Thème',
      'settings_language' : 'Langue',
      'settings_left_handed' : 'Mode gaucher',
      'settings_left_handed_2' : 'Définit par défaut la direction du pendage dans le sens (anti)horaire par rapport à l\'azimut mesuré. '
          'La direction reste modifiable manuellement lors de la mesure.',
      'settings_bearing_type' : 'Nord (boussole)',
      'settings_bearing_type_2' : 'Nord magnétique ou géographique',
      'settings_magnetic' : 'Magnétique',
      'settings_geographic' : 'Géographique)',
      'settings_bearing_type_warning' : 'Attention: L\'option "Nord géographique" nécessite la permission utilisateur de géolocalisation.',
      'settings_level_style' : 'Style de l\'indicateur horizontal',
      'settings_level_style_2' : 'Le style de l\'indicateur d\'aide sur la boussole',
      'settings_bubble' : 'Niveau à bulle',
      'settings_crosshair' : 'Croix',
      'settings_inclino_style' : 'Style de l\'inclinomètre',
      'settings_inclino_style_2' : 'Mesurez le pendage avec le téléphone maintenu à plat contre, ou le long de la surface.',
      'settings_ridge' : 'Longueur',
      'settings_flat' : 'Plat',
      'settings_coord_style' : 'Coordonnées GPS',
      'settings_coord_style_2' : 'Le format d\'affichage des coordonnées GPS.',
      'settings_geoloc_status' : 'Status de la géolocalisation:',
      'settings_geoloc_request' : 'Gérer les permissions',
      'settings_permission_previously_denied' : 'La permission de géolocalisation a été définitivement refusée. Vous pouvez changer cela depuis les paramètres d\'application de votre téléphone.',
      'settings_location_disabled' : '❌ Service indisponible',
      'settings_location_denied' : '⚠️ Permission non accordée',
      'settings_location_denied_forever' : '🚫 Permission définitivement refusée',
      'settings_location_granted' : '✅ Permission accordée',
      'settings_location_getting' : '\n Chargement...',

      // geo_measurement_widget.dart
      'measure_add_measure' : 'Ajouter une mesure',
      'measure_bearing' : 'Horizontale',
      'measure_inclination' : 'Pendage',
      'measure_direction' : 'Direction',
      'measure_final_save' : 'Confirmation',
      'measure_no_compass_data' : 'Aucune données reçues de la boussole',
      'measure_bearing_heading' : 'Azimut / Horizontale',
      'measure_bearing_heading_2' : '(maintenir le téléphone à plat pour une meilleure précision)',
      'measure_slope_angle' : 'Pendange / Inclinaison',
      'measure_hold_flat' : '(posez le téléphone à plat contre la surface)',
      'measure_hold_ridge' : '(maintenez la longueur du téléphone contre la surface)',
      'measure_dip_direction' : 'Direction du pendage',
      'measure_missing_bearing' : 'Direction de l\'horizontale manquante. Assurez-vous d\'enregistrer d\'abord une direction dans l\'onglet "Azimut".',
      'measure_save' : 'Sauvegarder',
      'measure_cancel' : 'Annuler',
      'measure_edit' : 'Modifier',
      'measure_geoloc_unavailable' : 'La géolocalisation est indisponible ou ne dispose pas des autorisations utilisateur requises.',
      'measure_notes' : 'Notes:',
      'measure_add_notes' : 'Ajouter des notes...',
      'measure_no_notes' : 'Pas de notes',
      'measure_save_measure' : 'Sauvegarder la mesure',
      'measure_saving' : 'Sauvegarde...',
      'measure_saved' : 'Mesure sauvegardée!',

      // geo_measurement_summary_util.dart
      'util_unnamed_measure' : 'Mesure sans nom',
      'util_edit' : 'Modifier',
      'util_gps_loc' : 'Position GPS',
      'util_latitude' : 'Latitude',
      'util_longitude' : 'Longitude',
      'util_comp_bearing' : 'Horizontale (azimut)',
      'util_bearing' : 'Direction',
      'util_orientation' : 'Pendage',
      'util_pitch' : 'Inclinaison (angle à l\'horizontale)',
      'util_direction' : 'Direction',
      'util_delete' : 'Supprimer',
      'util_east_oriented' : 'Orienté Est',
      'util_west_oriented' : 'Orienté Ouest',
      'util_north_oriented' : 'Orienté Nord',
      'util_south_oriented' : 'Orienté Sud',

      // geo_measurement_provider.dart
      'measureP_point' : 'Point',
      'measureP_measure' : 'Mesure',

      // measurement_summary.dart
      'measureS_BEARING' : 'DIRECTION',
      'measureS_DIP' : 'PENDAGE',
      'measureS_COORD' : 'COORDONNÉES',
      'measureS_coord_not_avail' : 'Coordonnées indisponibles',

      // generic_value_save_button.dart
      'saveBtn_save' : 'Enregistrer',

      // dip_direction_painter.dart
      'painter_strike_warning' : 'L\'horizontale est approximativement E-W. Sélectionnez la direction du pendage:',
      'painter_SOUTH' : 'SUD',
      'painter_WEST' : 'OUEST',
      'painter_NORTH' : 'NORD',
      'painter_EAST' : 'EST',
      'painter_EAST_WEST' : 'EST/OUEST',
      'painter_NORTH_SOUTH' : 'NORD/SUD',

      // session_widget.dart
      'session_details' : 'Détails de la session',
      'session_not_found' : 'Session introuvable.',
      'session_measurements' : 'Mesures',
      'session_add' : 'Ajouter',
      'session_no_measure' : 'Aucune mesure pour le moment.\n"+ Ajouter" pour en créer une.',
      'session_Delete_Measurement' : 'Suppression de mesure',
      'session_Delete_measurement' : 'Supprimer la mesure',
      'session_cancel' : 'Annuler',
      'session_delete' : 'Supprimer',
      'session_save' : 'Sauvegarder',
      'session_edit' : 'Modifier',
      'session_sessionId' : 'Numéro de session',
      'session_created' : 'Créée',
      'session_last_modif' : 'Modifiée',
      'session_notes' : 'Notes:',
      'session_add_notes' : 'Ajoutez des notes concernant cette session...',
      'session_no_notes' : 'Pas de notes',
      'session_saved' : 'Session modifiée avec succès',

      // session_list_widget.dart
      'session_sessions' : 'Sessions',
      'session_new_session' : 'Commencer une nouvelle session',
      'session_new_session_2' : 'Démarrer une nouvelle session avec une nouvelle mesure',
      'session_list_created' : 'Créée:',
      'session_list_last_modified' : 'Modifiée:',
      'session_list_measurements' : 'mesures',
      'session_list_measurement' : 'mesure',
    },
  };

  void setLanguage(String language) {
    _currentLang = language;
    notifyListeners();
  }

  // Get translation for a key
  String translate(String key) {
    return _translations[_currentLang]?[key] ?? '⚠️$key';
  }
}

// Extension for clean syntax
extension StringTranslation on String {
  String get tr => TranslationService.instance.translate(this);
}