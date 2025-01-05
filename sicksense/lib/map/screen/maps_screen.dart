import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({Key? key}) : super(key: key);

  @override
  _MapsScreenState createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  late GoogleMapController mapController;
  final LatLng _initialPosition = const LatLng(10.7769, 106.7009); // TPHCM
  LatLng? _currentPosition;

  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  final List<Map<String, dynamic>> _pharmacies = [
    {'name': 'Nhà thuốc A', 'location': LatLng(10.7770, 106.7000)},
    {'name': 'Nhà thuốc B', 'location': LatLng(10.7775, 106.7015)},
    {'name': 'Nhà thuốc C', 'location': LatLng(10.7800, 106.7030)},
    {'name': 'Nhà thuốc D', 'location': LatLng(10.7750, 106.6980)},
    {'name': 'Nhà thuốc E', 'location': LatLng(10.7765, 106.7050)},
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage("GPS chưa được bật.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showMessage("Quyền định vị bị từ chối.");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage("Quyền định vị bị từ chối vĩnh viễn.");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _updateMarkerAndCircle(_currentPosition!);
        _addNearbyPharmacyMarkers(_currentPosition!);
      });

      if (mapController != null && _currentPosition != null) {
        mapController.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition!, 15.0),
        );
      }
    } catch (e) {
      _showMessage("Lỗi khi lấy vị trí hiện tại: $e");
    }
  }

  void _updateMarkerAndCircle(LatLng position) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: position,
          infoWindow: const InfoWindow(title: "Vị trí hiện tại"),
        )
      };

      _circles = {
        Circle(
          circleId: const CircleId('currentLocationCircle'),
          center: position,
          radius: 500, // Bán kính 500m
          fillColor: Colors.blue.withOpacity(0.3),
          strokeColor: Colors.blue,
          strokeWidth: 2,
        ),
      };
    });
  }

  void _addNearbyPharmacyMarkers(LatLng currentPosition) {
    setState(() {
      for (var pharmacy in _pharmacies) {
        final pharmacyPosition = pharmacy['location'] as LatLng;
        final distance = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          pharmacyPosition.latitude,
          pharmacyPosition.longitude,
        );

        if (distance <= 500) {
          _markers.add(
            Marker(
              markerId: MarkerId(pharmacy['name']),
              position: pharmacyPosition,
              infoWindow: InfoWindow(title: pharmacy['name']),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen),
            ),
          );
        }
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;

    if (_currentPosition != null) {
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 15.0),
      );
    } else {
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_initialPosition, 15.0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps Example'),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? _initialPosition,
              zoom: 15.0,
            ),
            markers: _markers,
            circles: _circles,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location),
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
