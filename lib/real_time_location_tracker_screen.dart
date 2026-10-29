import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RealTimeLocationTrackerScreen extends StatefulWidget {
  const RealTimeLocationTrackerScreen({super.key});

  @override
  State<RealTimeLocationTrackerScreen> createState() =>
      _RealTimeLocationTrackerScreenState();
}

class _RealTimeLocationTrackerScreenState
    extends State<RealTimeLocationTrackerScreen> {
  GoogleMapController? _mapController;
  Timer? _locationTimer;

  // Polyline points tracking previous and current locations
  final List<LatLng> _polylinePoints = [];

  // Markers and Polylines sets for GoogleMap widget
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // Current tracked position
  Position? _currentPosition;
  bool _isLoading = true;
  String? _statusMessage;

  // Default camera target (Dhaka, Bangladesh as fallback)
  static const LatLng _defaultLocation = LatLng(23.7216771, 90.4165835);

  @override
  void initState() {
    super.initState();
    _initializeLocationTracking();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// Check permissions, get initial location and start 10s periodic updates
  Future<void> _initializeLocationTracking() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Location permission is required.';
        });
      }
      return;
    }

    // 1. Fetch initial location and animate camera
    await _fetchCurrentLocation(animateCamera: true);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    // 2. Fetch user's current location every 10 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchCurrentLocation(animateCamera: true);
    });
  }

  /// Verify and request location services and permissions
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled. Please enable GPS.'),
          ),
        );
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permissions are permanently denied. Please enable them in App Settings.',
            ),
          ),
        );
      }
      return false;
    }

    return true;
  }

  /// Fetch location, update marker, polyline, and camera animation
  Future<void> _fetchCurrentLocation({bool animateCamera = true}) async {
    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final LatLng newLatLng = LatLng(position.latitude, position.longitude);

      if (!mounted) return;

      setState(() {
        _currentPosition = position;

        // 3. Polyline Tracking: Draw polyline connecting previous and current locations
        if (_polylinePoints.isEmpty ||
            _polylinePoints.last.latitude != newLatLng.latitude ||
            _polylinePoints.last.longitude != newLatLng.longitude) {
          _polylinePoints.add(newLatLng);
        }

        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('tracking_polyline'),
            points: List<LatLng>.from(_polylinePoints),
            color: const Color(0xFF2979FF), // Vibrant blue route line
            width: 5,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );

        // 2 & 4. Update marker's position and InfoWindow
        const markerId = MarkerId('user_current_location');
        _markers.clear();
        _markers.add(
          Marker(
            markerId: markerId,
            position: newLatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: 'My Current Location',
              snippet: '${position.latitude},${position.longitude}',
            ),
            onTap: () {
              _mapController?.showMarkerInfoWindow(markerId);
            },
          ),
        );
      });

      // 1. Automatic Map Animation: Smoothly animate to user's current location
      if (animateCamera && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: newLatLng,
              zoom: 16.0,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error fetching location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initialTarget = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : _defaultLocation;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Real-Time Location Tracker',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF2196F3), // Material Blue
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 15.0,
            ),
            mapType: MapType.normal,
            myLocationEnabled: false,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            compassEnabled: true,
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (_currentPosition != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      zoom: 16.0,
                    ),
                  ),
                );
              }
            },
          ),

          // Loading overlay if initial location is being fetched
          if (_isLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.6),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Locating...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Error/Status message banner if any
          if (_statusMessage != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.red.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

