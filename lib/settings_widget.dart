import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:geolocator/geolocator.dart';

import 'settings_provider.dart';
import 'translation_util/translation_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenTab();
}

class _SettingsScreenTab extends State<SettingsScreen> {

  bool _locationStatus = false;
  String _locationStatusMessage = 'settings_checking'.tr; // 'Checking...';
  int _geolocAuthorizationRequestCounter = 0;

  // true if user tried to change geolocation authorization and app settings failed to open automatically.
  bool _failedToOpenAppSettings = false;

  @override
  void initState() {
    super.initState();

    _checkLocationStatus();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('settings_title'.tr)), // 'Settings'
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: ListView(
          children: [
            // Theme mode (light - dark)
            ListTile(
              title: Text('settings_theme'.tr), // 'Theme'
              trailing: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey[300],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.light_mode),
                      color: !settings.isDarkMode ? Colors.orange : Colors.grey,
                      onPressed: () => settings.setDarkMode(false),
                    ),
                    IconButton(
                      icon: Icon(Icons.dark_mode),
                      color: settings.isDarkMode ? Colors.blue : Colors.grey,
                      onPressed: () => settings.setDarkMode(true),
                    ),
                  ],
                ),
              ),
            ),

            // Localization / Language
            ListTile(
              title: Text('settings_language'.tr), // 'Language'
              trailing: DropdownButton<String>(
                value: settings.language,
                items: const [
                  DropdownMenuItem(
                    value: 'fr',
                    child: Text('Français'),
                  ),
                  DropdownMenuItem(
                    value: 'en',
                    child: Text('English'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) settings.setLanguage(value);
                },
              ),
            ),

            // Left-handed mode
            SwitchListTile(
              title: Text('settings_left_handed'.tr), // 'Left-Handed Mode'
              subtitle: Text('settings_left_handed_2'.tr),
              // 'Defaults the dip direction to be (counter)clockwise to the measured bearing. '
              // 'You can always change it manually when taking a measurement.'
              value: settings.isLeftHanded,
              onChanged: (value) => settings.setLeftHanded(value),
            ),

            const Divider(),

            ListTile(
              title: Text('settings_bearing_type'.tr), // 'Bearing Type'
              subtitle: Text('settings_bearing_type_2'.tr), // 'Magnetic or True North'
              trailing: DropdownButton<BearingType>(
                value: settings.bearingType,
                items: [
                  DropdownMenuItem(
                    value: BearingType.MAGNETIC,
                    child: Text('settings_magnetic'.tr), // 'Magnetic'
                  ),
                  DropdownMenuItem(
                    value: BearingType.GEOGRAPHIC,
                    child: Text('settings_geographic'.tr), // 'True (Geographic)'
                  ),
                ],
                onChanged: (value) {
                  if (value != null) settings.setBearingType(value);
                },
              ),
            ),

            if (settings.bearingType == BearingType.GEOGRAPHIC && !_locationStatus) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child:
                  Center(
                    child: Text('settings_bearing_type_warning'.tr,
                      // 'Warning: Geographic bearing will default to magnetic if geolocation permission is not granted.'
                      style: TextStyle(color: Colors.amber),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ),
            ],

            // Level Indicator Style
            ListTile(
              title: Text('settings_level_style'.tr), // 'Level Indicator Style'),
              subtitle: Text('settings_level_style_2'.tr), // 'Choose visual style for level indicator on compass and clinometer'),
              trailing: DropdownButton<LevelIndicatorStyle>(
                value: settings.levelIndicatorStyle,
                items: [
                  DropdownMenuItem(
                    value: LevelIndicatorStyle.BUBBLE,
                    child: Text('settings_bubble'.tr), // 'Bubble'),
                  ),
                  DropdownMenuItem(
                    value: LevelIndicatorStyle.CROSSHAIR,
                    child: Text('settings_crosshair'.tr), // 'Crosshair'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) settings.setLevelIndicator(value);
                },
              ),
            ),

            // Clinometer Style
            ListTile(
              title: Text('settings_inclino_style'.tr), // 'Clinometer Style'),
              subtitle: Text('settings_inclino_style_2'.tr), // 'Hold the phone\'s ridge, or the phone flat against the surface.'),
              trailing: DropdownButton<ClinometerStyle>(
                value: settings.clinometerStyle,
                items: [
                  DropdownMenuItem(
                    value: ClinometerStyle.RIDGE,
                    child: Text('settings_ridge'.tr), // 'Ridge'),
                  ),
                  DropdownMenuItem(
                    value: ClinometerStyle.FLAT,
                    child: Text('settings_flat'.tr), // 'Flat'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) settings.setClinometerStyle(value);
                },
              ),
            ),

            const Divider(),

            // Coordinates Display Format
            ListTile(
              title: Text('settings_coord_style'.tr), // 'Coordinates Format'),
              subtitle: Text('settings_coord_style_2'.tr), // 'How GPS coordinates are displayed'),
              trailing: DropdownButton<CoordinatesDisplayFormat>(
                value: settings.coordDisplayFormat,
                items: const [
                  DropdownMenuItem(
                    value: CoordinatesDisplayFormat.DD,
                    child: Text('DD (40.7128°)'),
                  ),
                  DropdownMenuItem(
                    value: CoordinatesDisplayFormat.SDD,
                    child: Text('SDD (40.7128)'),
                  ),
                  DropdownMenuItem(
                    value: CoordinatesDisplayFormat.DMM,
                    child: Text('DMM (40° 42.768\')'),
                  ),
                  DropdownMenuItem(
                    value: CoordinatesDisplayFormat.DMS,
                    child: Text('DMS (40° 42\' 46")'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) settings.setCoordDisplayFormat(value);
                },
              ),
            ),

            const SizedBox(height: 30),

            // Geolocation authorization
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 0.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text('settings_geoloc_status'.tr, // 'Geolocation Status:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_locationStatusMessage, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _requestPermission,
                          child: Text('settings_geoloc_request'.tr), // 'Set Geolocation Permission'),
                        ),
                      ],
                    ),
                  ),

                  if (_failedToOpenAppSettings) ...[
                    const SizedBox(height: 8),
                    Text('settings_permission_previously_denied'.tr,
                      // 'Permission was previously permanently denied. You can change this by accessing your phone\'s settings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  //* Geolocation permission helper functions *//

  Future<void> _checkLocationStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    bool permissionStatus = false;
    String statusMessage = '';

    if (!serviceEnabled) {
      permissionStatus = false;
      statusMessage = 'settings_location_disabled'.tr; // '❌ Location services disabled';
    } else if (permission == LocationPermission.denied) {
      permissionStatus = false;
      statusMessage = 'settings_location_denied'.tr; // '⚠️ Location permission not granted';
    } else if (permission == LocationPermission.deniedForever) {
      permissionStatus = false;
      statusMessage = 'settings_location_denied_forever'.tr; // '🚫 Location permission permanently denied';
    } else if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      permissionStatus = true;
      statusMessage = 'settings_location_granted'.tr; // '✅ Location permission granted';
    }

    setState(() {
      _locationStatus = permissionStatus;
      _locationStatusMessage = statusMessage;
    });
  }

  Future<void> _requestPermission() async {
    // First check the current permission status
    LocationPermission permission = await Geolocator.checkPermission();


    // Permission already determined - open app settings
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      final settingsOpened = await Geolocator.openAppSettings();
      setState(() {
        _failedToOpenAppSettings = !settingsOpened;
      });

      // Permission is "denied" : three cases :
      // 1 - denied means we never asked for permission before
      // 2 - denied means the user denied once, we can still ask one more time.
      // 3 - denied means it was denied twice, and authorization requests do not actually show up for the user.
    } else if (permission == LocationPermission.denied) {

      // In case 3, this actually does nothing on the user side.
      permission = await Geolocator.requestPermission();

      // Case 1 or 2, and user confirmed denied access
      if (permission == LocationPermission.denied && _geolocAuthorizationRequestCounter < 2) {
        _geolocAuthorizationRequestCounter += 1;

        // Case 3, request didn't even show up, attempt to open phone's settings
        // Somehow, deniedForever sometimes shows up in this scenario. I assume checkPermission returns denied, and requestPermission returns deniedForever. Somehow.
      } else if (permission == LocationPermission.deniedForever ||
          (permission == LocationPermission.denied && _geolocAuthorizationRequestCounter >= 2)) {
        final settingsOpened = await Geolocator.openAppSettings();
        setState(() {
          _failedToOpenAppSettings = !settingsOpened;
        });

        // User granted request
      } else if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        _geolocAuthorizationRequestCounter = 0;
      }
    }






    _checkLocationStatus();
  }
}