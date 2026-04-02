// Native
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
// import 'package:vector_math/vector_math_64.dart' hide Colors;

// Sensor libraries
import 'package:geolocator/geolocator.dart';
import 'package:dchs_motion_sensors/dchs_motion_sensors.dart';
import 'package:lat_compass/lat_compass.dart';

// Project
import 'geo_measurement_class.dart';
import 'geo_measurement_provider.dart';
import 'geo_measurement_widget_util/compass_painter.dart';
import 'geo_measurement_widget_util/clinometer_painter.dart';
import 'geo_measurement_widget_util/dip_direction_painter.dart';
import 'geo_measurement_widget_util/generic_value_save_button.dart';
import 'geo_measurement_widget_util/measurement_summary.dart';
import 'session_widget.dart';
import 'settings_widget.dart';
import 'settings_provider.dart';

import 'translation_util/translation_service.dart';

//*** Widget for the creation workflow of a single GeologicalMeasurement ***//
class MeasureTakerFlow extends StatefulWidget {
  final int? sessionId;

  const MeasureTakerFlow({super.key, this.sessionId});

  @override
  State<MeasureTakerFlow> createState() => _MeasureTakerFlowState();
}

class _MeasureTakerFlowState extends State<MeasureTakerFlow> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    if (widget.sessionId != null) {
      Provider
          .of<MeasurementProvider>(context, listen: false)
          .currentSessionId = widget.sessionId;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('measure_add_measure'.tr), // 'Add a measure'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: 'settings_title'.tr, // 'Settings',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'measure_bearing'.tr), // 'Bearing'),
            Tab(text: 'measure_inclination'.tr), // 'Inclination'),
            Tab(text: 'measure_direction'.tr), // Direction'),
            Tab(text: 'measure_final_save'.tr), // 'Final save'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          BearingTab(onNavigate: () => _tabController.animateTo(1)),
          SlopeAngleTab(onNavigate: () => _tabController.animateTo(2)),
          DipDirectionTab(onNavigate: () => _tabController.animateTo(3)),
          FinalSaveTab(),
        ],
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }
}


// Tab 1: Get position and take bearing (phone flat)
class BearingTab extends StatefulWidget {
  final VoidCallback onNavigate;

  const BearingTab({super.key, required this.onNavigate});

  @override
  State<BearingTab> createState() => _BearingTabState();
}

class _BearingTabState extends State<BearingTab> {
  late StreamSubscription<AbsoluteOrientationEvent> _orientationSub;

  double? resValue; // Saved value.

  double pitch = 0.0;
  double roll = 0.0;

  @override
  void initState() {
    super.initState();

    _orientationSub = motionSensors.absoluteOrientation.listen((event) {
      setState(() {
        pitch = event.pitch;
        roll = event.roll;
      });
    });

    MeasurementProvider measurementProvider = Provider.of<MeasurementProvider>(context, listen: false);
    if (measurementProvider.currentMeasurement.bearing != null) {
      resValue = measurementProvider.currentMeasurement.bearing!;
    }

    _checkLocationStatus();
  }

  @override
  void dispose() {
    _orientationSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    final isDark = settings.isDarkMode;

    return StreamBuilder(
      stream: LatCompass().onUpdate,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text('measure_no_compass_data'.tr); // 'No compass data');
        }
        final compassData = snapshot.data!;
        return Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // *** Visual Compass *** //
                    Text(
                      'measure_bearing_heading'.tr, // 'Bearing / Heading',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'measure_bearing_heading_2'.tr, // '(hold phone flat for best accuracy)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: 320,
                      height: 320,
                      child: CustomPaint(
                        painter: CompassPainter(
                          settings.bearingType == BearingType.MAGNETIC
                            ? compassData.magneticHeading
                            : compassData.trueHeading,
                          pitch,
                          roll,
                          isDark: isDark,
                          levelIndicatorStyle: settings.levelIndicatorStyle,
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    Text(
                      '${_limitTo180Degrees(
                          settings.bearingType == BearingType.MAGNETIC
                            ? compassData.magneticHeading
                            : compassData.trueHeading
                        ).toStringAsFixed(0)}°',
                      style: TextStyle(
                          fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),
                    ValueSaveButton(
                      value: (resValue == null) ? '--' : '${_limitTo180Degrees(_radiansToDegrees(resValue!)).toStringAsFixed(0)}°',
                      onSave: () {
                        _saveMeasure(
                          context,
                          _degreesToRadians(
                            (settings.bearingType == BearingType.MAGNETIC)
                              ? compassData.magneticHeading
                              : compassData.trueHeading
                          )
                        );
                        widget.onNavigate();
                      },
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }


  // -- Helper functions for geolocation -- //

  // Ask for geolocation permission if permission hasn't been explicitly granted or denied yet.
  Future<void> _checkLocationStatus() async {
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (isLocationServiceEnabled) {
      LocationPermission permission = await Geolocator.checkPermission();
      // if permission not yet determined
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    }
  }

  // -- Other utility functions -- //

  void _saveMeasure(BuildContext context, double value) {
    final provider = Provider.of<MeasurementProvider>(context, listen: false);
    provider.updateBearing(value);
    provider.updateEastWestOrientation(DipDirection.blank);

    resValue = value;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  double _radiansToDegrees(double radians) {
    return radians * (180 / pi);
  }

  double _limitTo180Degrees(double degrees) {
    if (degrees > 180) {
      return degrees - 180;
    }
    return degrees;
  }
}


// Tab 2: Measure the angle of the slope, phone straight.
class SlopeAngleTab extends StatefulWidget {
  final VoidCallback onNavigate;

  const SlopeAngleTab({super.key, required this.onNavigate});

  @override
  State<SlopeAngleTab> createState() => _SlopeAngleTabState();
}

class _SlopeAngleTabState extends State<SlopeAngleTab> {
  late StreamSubscription<AbsoluteOrientationEvent> _orientationSub;


  //** Ongoing test **//
  // late StreamSubscription<AccelerometerEvent> _accelerometerSub;
  // Vector3? _gravity;
  // double pitch2 = 0.0;
  //** End test **//


  double? resValue; // The final value to save, irrespective of measurement mode.

  double pitch = 0.0; // The angle of the slope, when measuring with the phone's ridge against the slope.
  double roll = 0.0; // The roll of the phone, used to measure tilt.
  // double stableRoll = 0.0; // The roll, computed from the accelerometer, more reliable at pitch = pi/2.
  double tilt = 0.0; // The angle of the slope, when measuring with the phone flat against the slope.

  @override
  void initState() {
    super.initState();
    _orientationSub = motionSensors.absoluteOrientation.listen((event) {
      setState(() {
        pitch = event.pitch;
        roll = event.roll;

        // correctedPitch = atan( tan(pitch) / cos(event.roll) ); // A slightly better pitch for values neighbouring 90 degrees. Ignores slight tilt offset from the vertical plane.
        // if (pitch > 1.396) { // 80 degrees in radians
        //   pitch = -correctedPitch;
        // }

        tilt = acos(cos(pitch) * cos(roll));
      });
    });

    // Equivalent measures using AccelerometerEvent
    //
    // _accelerometerSub = motionSensors.accelerometer.listen((event) {
    //   setState(() {
    //     pitch = atan2(event.y, event.z);
    //     roll = atan2(event.x, event.z);
    //     tilt = acos(event.z / sqrt(event.x*event.x + event.y*event.y + event.z*event.z));
    //  });
    // });

    // _accelerometerSub = motionSensors.accelerometer.listen((event) {
    //   setState(() {
    //     final g = Vector3(event.x, event.y, event.z);

    //     // Normalize → keep only direction
    //     g.normalize();

    //     _gravity = g;
    //     if (_gravity != null) {
    //       final eDevice = Vector3(1, 0, 0); // right edge

    //       // Dot product = sin(theta)
    //       final dot = _gravity!.dot(eDevice).clamp(-1.0, 1.0);

    //       final slopeRad = asin(dot);

    //       setState(() {
    //         pitch2 = slopeRad.abs(); // usually you want magnitude
    //       });
    //     }
    //   });
    // });

    // The roll, computed from the accelerometer, more reliable at pitch = pi/2.
    //
    // motionSensors.accelerometerUpdateInterval =
    //     Duration.microsecondsPerSecond ~/ 60;
    //
    // motionSensors.accelerometer.listen((event) {
    //   double ax = event.x;
    //   double ay = event.y;
    //   double az = event.z;
    //
    //   final norm = sqrt(ax * ax + ay * ay + az * az);
    //   ax /= norm;
    //   ay /= norm;
    //   az /= norm;
    //   final newRoll = atan2(az, sqrt(ax*ax + ay*ay));
    //
    //   setState(() {
    //     stableRoll = 0.85 * stableRoll + 0.15 * newRoll; // Smoothing to avoid jittering.
    //   });
    // });

    MeasurementProvider measurementProvider = Provider.of<MeasurementProvider>(context, listen: false);
    if (measurementProvider.currentMeasurement.pitch != null) {
      resValue = measurementProvider.currentMeasurement.pitch!;
    }

  }

  @override
  void dispose() {
    _orientationSub.cancel();
    // _accelerometerSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    final isDark = settings.isDarkMode;

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                /*

                //*** AVIATOR STYLE DISPLAY FOR FLAT PHONE USAGE ***//
                if (settings.clinometerStyle == ClinometerStyle.FLAT) ...[
                  Text(
                    'measure_slope_angle'.tr, // 'Slope angle',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'measure_hold_flat'.tr, // '(press phone flat against slope)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: 320,
                    height: 320,
                    child: CustomPaint(
                      painter: PitchPainter (
                        _radiansToDegrees(tilt),
                        isDark: isDark,
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    '${_radiansToDegrees(tilt).toStringAsFixed(0)}°',
                    style: TextStyle(
                        fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 30),
                  ValueSaveButton(
                    value: (resValue == null) ? '--' : '${_radiansToDegrees(resValue!).toStringAsFixed(0)}°',
                    onSave: () { _saveMeasure(context, tilt); },
                  ),
                  SizedBox(height: 30),
                ],

                //*** CLINOMETER STYLE DISPLAY FOR RIDGE PHONE USAGE ***/
                if (settings.clinometerStyle == ClinometerStyle.RIDGE) ...[
                */


                //*** CLINOMETER STYLE DISPLAY FOR RIDGE PHONE USAGE ***/
                Text(
                  'measure_slope_angle'.tr, // 'Slope angle',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'measure_hold_ridge'.tr, // '(press phone\'s ridge against slope)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Container(
                  width: 320,
                  height: 320,
                  child: CustomPaint(
                    painter: ClinometerPainter(
                      (roll > 0) ? (pi/2) - pitch : (pi/2) + pitch,
                      isDark: isDark,
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  '${_radiansToDegrees(pitch.abs()).toStringAsFixed(0)}°',
                  style: TextStyle(
                      fontSize: 48, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 30),
                ValueSaveButton(
                  value: (resValue == null) ? '--' : '${_radiansToDegrees(resValue!).toStringAsFixed(0)}°',
                  onSave: () {
                    _saveMeasure(context, pitch.abs());
                    widget.onNavigate();
                  },
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveMeasure(BuildContext context, double value) {
    final provider = Provider.of<MeasurementProvider>(context, listen: false);
    provider.updateInclination(value);

    resValue = value;
  }

  double _radiansToDegrees(double radians) {
    return radians * (180 / pi);
  }

}


// Tab 3: Input slope orientation
class DipDirectionTab extends StatefulWidget {
  final VoidCallback onNavigate;

  const DipDirectionTab({super.key, required this.onNavigate});

  @override
  State<DipDirectionTab> createState() => _DipDirectionTabState();
}

class _DipDirectionTabState extends State<DipDirectionTab> {

  late DipDirection _selectedDirection;
  late bool _is_E_W_EdgeCase; // True if bearing is straight East:West, meaning possible dip orientation being North/South.

  bool _isCompassLocked = true;

  @override
  void initState() {
    super.initState();

    _reload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _reload();
  }

  void _reload() {
    final measurementProvider = Provider.of<MeasurementProvider>(context, listen: false);
    _selectedDirection = measurementProvider.currentMeasurement.dipDirection;

    final suggestedDir = suggestedDirection(
      (measurementProvider.currentMeasurement.bearing != null)
          ? _radiansToDegrees(measurementProvider.currentMeasurement.bearing!)
          : null,
      false,
      context.read<SettingsProvider>().isLeftHanded,
    );

    if (_selectedDirection == DipDirection.blank) {_selectedDirection = suggestedDir;}

    _is_E_W_EdgeCase = (suggestedDir == DipDirection.north) || (suggestedDir == DipDirection.south);
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final measurementProvider = Provider.of<MeasurementProvider>(context);

    final isDark = settings.isDarkMode;
    final isLeftHanded = settings.isLeftHanded;

    final accent = Colors.blue.shade400; // TODO I don't like hardcoding the color here

    return StreamBuilder(
      stream: LatCompass().onUpdate,
      builder: (context, snapshot) {
        bool currentBearingAvailable = snapshot.hasData;

        double rotation = 0.0;

        if (!_isCompassLocked && currentBearingAvailable) {
          rotation = settings.bearingType == BearingType.MAGNETIC
            ? _degreesToRadians(snapshot.data!.magneticHeading)
            : _degreesToRadians(snapshot.data!.trueHeading);
        }


        return Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Compass Display ── //
                    Text(
                      'measure_dip_direction'.tr, // 'Dip direction',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),

                    Center(
                      child: SizedBox(
                        width: 320.0,
                        height: 320.0,
                        child: Stack(
                          children: [

                            // Compass display
                            AnimatedRotation(
                              turns: -rotation / (2 * pi), // AnimatedRotation uses "turns" not radians
                              duration: Duration(milliseconds: 0),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  const size = 320.0;
                                  return SizedBox(
                                    width: size,
                                    height: size,
                                    child: CustomPaint(
                                      painter: SlopeBearingPainter(
                                        bearing: (measurementProvider
                                            .currentMeasurement.bearing != null)
                                            ? _radiansToDegrees(
                                              measurementProvider
                                                .currentMeasurement.bearing!)
                                            : null,
                                        selectedDirection: _selectedDirection,
                                        isDark: isDark,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Compass lock button
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[800] : Colors
                                      .white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: Icon(
                                      _isCompassLocked ? Icons.lock : Icons
                                          .lock_open),
                                  onPressed: () =>
                                    currentBearingAvailable ?
                                      setState(() =>
                                      _isCompassLocked = !_isCompassLocked)
                                    : null,
                                  color: _isCompassLocked
                                    ? Colors.blueAccent
                                    : Colors.blue,
                                  iconSize: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Direction Selection ── //
                    if (measurementProvider.currentMeasurement.bearing !=
                        null) ...[
                      DipDirectionSelector(
                        currentSelection: _selectedDirection,
                        accent: accent,
                        isDark: isDark,
                        is_E_W_EdgeCase: _is_E_W_EdgeCase,
                        onSelect: (dir) {
                          setState(() => _selectedDirection = dir);
                        },
                        onForceE_W: (isForcingE_W) {
                          setState(() =>
                          _selectedDirection = suggestedDirection(
                              _radiansToDegrees(
                                  measurementProvider.currentMeasurement
                                      .bearing!), isForcingE_W, isLeftHanded));
                        },
                      ),
                    ] else
                      ...[
                        Text(
                          'measure_missing_bearing'.tr, // 'Missing strike bearing information. Make sure to first save a bearing in the "Bearing" tab.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    const SizedBox(height: 24),
                    ValueSaveButton(
                      value: dipDirectionLabel(
                          measurementProvider.currentMeasurement.dipDirection),
                      onSave:
                        measurementProvider.currentMeasurement.bearing != null
                          ? () {
                              _saveDirection(context, _selectedDirection);
                              widget.onNavigate();
                            }
                          : null,
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }


  // *** Utils *** //

  String dipDirectionLabel(DipDirection dir) {
    switch (dir) {
      case DipDirection.east:
        return 'painter_EAST'.tr;
      case DipDirection.west:
        return 'painter_WEST'.tr;
      case DipDirection.north:
        return 'painter_NORTH'.tr;
      case DipDirection.south:
        return 'painter_SOUTH'.tr;
      case DipDirection.blank:
        return '--';
    }
  }

  Future<void> _saveDirection(BuildContext context, DipDirection direction) async {
    final provider = Provider.of<MeasurementProvider>(context, listen: false);

    provider.updateEastWestOrientation(direction);
  }

  double _radiansToDegrees(double radians) {
    return radians * (180 / pi);
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
}


// Tab 4 : Final edits and save
class FinalSaveTab extends StatefulWidget {

  const FinalSaveTab({super.key});

  @override
  State<FinalSaveTab> createState() => _FinalSaveTabState();
}

// Tab 4: final confirm of measurement,
class _FinalSaveTabState extends State<FinalSaveTab> {

  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _notesController;

  // Geolocation
  bool _locationStatus = true;
  String _locationStatusMessage = 'settings_checking'.tr; // 'Checking...'
  Position? _currentPosition;
  int _geolocAuthorizationRequestCounter = 0;

  // true if user tried to change geolocation authorization and app settings failed to open automatically.
  bool _failedToOpenAppSettings = false;

  @override
  void initState() {
    super.initState();

    final measurementProvider = Provider.of<MeasurementProvider>(context, listen: false);
    _nameController = TextEditingController(text: measurementProvider.currentMeasurement.name);
    _notesController = TextEditingController(text: measurementProvider.currentMeasurement.notes ?? '');

    _getGeolocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final measurementProvider = Provider.of<MeasurementProvider>(context, listen: false);

    final isDark = settings.isDarkMode;

    return Scaffold(
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Measurement name & edit buttons ── //
                  Row(
                    children: [
                      const SizedBox(width: 14),
                      Expanded(
                        child: _isEditing
                            ? TextField(
                          controller: _nameController,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                            border: UnderlineInputBorder(),
                          ),
                        )
                            : Text(
                          measurementProvider.currentMeasurement.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_isEditing) ...[
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: _saveChanges,
                          tooltip: 'measure_save'.tr, // 'Save',
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: _cancelEditing,
                          tooltip: 'measure_cancel'.tr, // 'Cancel',
                        ),
                      ] else ...[
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                          tooltip: 'measure_edit'.tr, // 'Edit',
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ── Measurement Summary ── //
                  MeasurementSummaryCard(
                    bearing: (measurementProvider.currentMeasurement.bearing != null) ? _limitTo180Degrees(_radiansToDegrees(measurementProvider.currentMeasurement.bearing!)) : null,
                    dipAngle: (measurementProvider.currentMeasurement.pitch != null) ? _radiansToDegrees(measurementProvider.currentMeasurement.pitch!) : null,
                    dipDirection: measurementProvider.currentMeasurement.dipDirection,
                    latitude: _currentPosition?.latitude,
                    longitude: _currentPosition?.longitude,
                    isDark: isDark,
                    coordDisplayFormat: settings.coordDisplayFormat,
                  ),

                  if (!_locationStatus) ...[
                    const SizedBox(height: 18),

                    Text(
                      'measure_geoloc_unavailable'.tr, // 'Geolocation is either unavailable or permission hasn\'t been granted.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.amber,
                      ),
                    ),

                    const SizedBox(height: 8),

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
                      Text(
                        'settings_permission_previously_denied'.tr, // 'Permission was previously permanently denied. You can change this by accessing your phone\'s settings.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 18),

                  // ── Notes Section ── //
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'measure_notes'.tr, // 'Notes:',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _isEditing
                      ? TextField(
                    controller: _notesController,
                    maxLines: 15,
                    minLines: 3,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'measure_add_notes'.tr, // 'Add notes...',
                      hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(8),
                    ),
                  )
                      : GestureDetector(
                    onTap: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        measurementProvider.currentMeasurement.notes?.isEmpty ?? true
                            ? 'measure_no_notes'.tr // 'No notes'
                            : measurementProvider.currentMeasurement.notes!,
                        style: TextStyle(
                          fontSize: 14,
                          color: measurementProvider.currentMeasurement.notes?.isEmpty ?? true
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Final Save ── //
                  CommitMeasurementButton(
                    onCommit: () async {
                      if (_isEditing) {
                        _saveChanges();
                      }
                      await _saveMeasurement(context);
                    },
                    onSuccess: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChangeNotifierProvider(
                            create: (_) => MeasurementProvider(),
                            child: MeasureTakerFlow(sessionId: measurementProvider.currentSessionId!),
                          )
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  // *** UTILS *** //

  // Ask for geolocation permission if permission hasn't been explicitly granted or denied yet.
  Future<void> _getGeolocation() async {
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();

    bool permissionStatus = false;
    String statusMessage = '';

    LocationPermission permission = await Geolocator.checkPermission();

    if (!isLocationServiceEnabled) {
      permissionStatus = false;
      statusMessage = 'settings_location_disabled'.tr; // '❌ Location services disabled';
    } else if (permission == LocationPermission.denied) {
      permissionStatus = false;
      statusMessage = 'settings_location_denied'.tr; // '⚠️ Location permission not granted';
    } else if (permission == LocationPermission.deniedForever ||
      (permission == LocationPermission.denied && _geolocAuthorizationRequestCounter >= 2)) {
      permissionStatus = false;
      statusMessage = 'settings_location_denied_forever'.tr; // '🚫 Location permission permanently denied';
    } else if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      permissionStatus = true;
      statusMessage = 'settings_location_granted'.tr; // '✅ Location permission granted';

      try {
        final position = await Geolocator.getCurrentPosition();

        setState(() {
          _currentPosition = position;
        });
      } catch (e) {
        _locationStatusMessage += 'settings_location_getting'.tr; // '\n Getting location...';
      }
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

    _getGeolocation();
  }

  void _saveChanges() {
    final provider = Provider.of<MeasurementProvider>(context, listen: false);

    provider.currentMeasurement.name = _nameController.text.trim();
    provider.currentMeasurement.notes = _notesController.text.trim();

    setState(() {
      _isEditing = false;
    });
  }

  void _cancelEditing() {
    final provider = Provider.of<MeasurementProvider>(context, listen: false);

    _nameController.text = provider.currentMeasurement.name;
    _notesController.text = provider.currentMeasurement.notes ?? '';

    setState(() {
      _isEditing = false;
    });
  }

  Future<void> _saveMeasurement(BuildContext context) async {
    final provider = Provider.of<MeasurementProvider>(context, listen: false);

    if (_currentPosition == null && _locationStatus) {
      await _getGeolocation();
    }
    if (_currentPosition != null) {
      provider.updateGPS(_currentPosition!.latitude, _currentPosition!.longitude);
    }

    await provider.saveMeasurement();
  }

  double _radiansToDegrees(double radians) {
    return radians * (180 / pi);
  }

  double _limitTo180Degrees(double degrees) {
    if (degrees > 180) {
      return degrees - 180;
    }
    return degrees;
  }
}


/// A prominent, final-action button for committing a Measurement.
class CommitMeasurementButton extends StatefulWidget {
  // Async work to perform on press (DB save, validation, etc.).
  // Throw an exception here to trigger the error snackbar instead.
  final Future<void> Function() onCommit;

  // Called after the success snackbar finishes — put navigation here.
  final VoidCallback onSuccess;

  // Optional label override.
  final String label;

  const CommitMeasurementButton({
    super.key,
    required this.onCommit,
    required this.onSuccess,
    this.label = 'measure_save_measure', // 'Save Measurement', // .tr is called in the build
  });

  @override
  State<CommitMeasurementButton> createState() => _CommitMeasurementButtonState();
}

class _CommitMeasurementButtonState extends State<CommitMeasurementButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilledButton.icon(
      onPressed: _isLoading ? null : _handlePress,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      icon: _isLoading
          ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: colorScheme.onPrimary,
        ),
      )
          : const Icon(Icons.check_circle_outline_rounded),
      label: Text(
        _isLoading ? 'measure_saving'.tr : widget.label.tr, // 'Saving...'
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Future<void> _handlePress() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await widget.onCommit();
      if (!mounted) return;
      _showSuccessSnackbar();
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar(e.toString());
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackbar() {
    final messenger = ScaffoldMessenger.of(context);

    // Clear any leftover snackbars from previous steps.
    messenger.clearSnackBars();

    messenger
        .showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'measure_saved'.tr, // 'Measurement saved!',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        duration: const Duration(milliseconds: 1000),
      ),
    )
        .closed
        .then((_) {
      // Navigate only after the snackbar has dismissed itself.
      if (mounted) widget.onSuccess();
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          duration: const Duration(milliseconds: 5000),
        ),
      );
  }
}