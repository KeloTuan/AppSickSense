import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

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
  final String _apiKey =
      'AIzaSyCifqIDaispEaShRMmXLUNiTnJ4R0QEgsk'; // Thay bằng API Key của bạn

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
        _findNearbyPharmacies();
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

  Future<void> _findNearbyPharmacies() async {
    if (_currentPosition == null) return;

    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${_currentPosition!.latitude},${_currentPosition!.longitude}&radius=3000&type=pharmacy&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          setState(() {
            _markers.clear();
            for (var result in results) {
              final location = result['geometry']['location'];
              final name = result['name'];
              final lat = location['lat'];
              final lng = location['lng'];

              _markers.add(
                Marker(
                  markerId: MarkerId(name),
                  position: LatLng(lat, lng),
                  infoWindow: InfoWindow(title: name),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen),
                ),
              );
            }
          });
        } else {
          _showMessage("Không tìm thấy nhà thuốc gần bạn.");
        }
      } else {
        _showMessage("Lỗi khi gọi API: ${response.statusCode}");
      }
    } catch (e) {
      _showMessage("Lỗi khi tìm kiếm nhà thuốc: $e");
    }
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
        title: const Text('Nhà thuốc gần đây'),
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
