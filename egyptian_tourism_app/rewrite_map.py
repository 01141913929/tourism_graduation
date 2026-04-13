import re

file_path = r"c:\Users\IT\.gemini\antigravity\scratch\egyptian_tourism_app\lib\features\map\screens\interactive_map_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Replace imports
content = content.replace("import 'package:flutter_map/flutter_map.dart';", "")
content = content.replace("import 'package:latlong2/latlong.dart';", "import 'package:google_maps_flutter/google_maps_flutter.dart';\nimport 'dart:ui' as ui;\nimport 'package:flutter/services.dart';")

# Controller, LatLng, Zoom
content = content.replace("final MapController _mapController = MapController();", "GoogleMapController? _mapController;\n  BitmapDescriptor? _markerOpen;\n  BitmapDescriptor? _markerClosed;\n  BitmapDescriptor? _markerSelected;")

# initState
old_init = "  void initState() {\n    super.initState();\n    _loadBazaars();\n    _getCurrentLocation();\n  }"
new_init = """  @override
  void initState() {
    super.initState();
    _initMarkers();
    _loadBazaars();
    _getCurrentLocation();
  }

  Future<void> _initMarkers() async {
    _markerOpen = await _createCustomMarkerBitmap(isOpen: true, isSelected: false);
    _markerClosed = await _createCustomMarkerBitmap(isOpen: false, isSelected: false);
    _markerSelected = await _createCustomMarkerBitmap(isOpen: true, isSelected: true);
    if (mounted) setState(() {});
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap({required bool isOpen, required bool isSelected}) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final size = isSelected ? 80.0 : 60.0;
    
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(Offset(size/2, size/2 + 2), size/2 - 4, shadowPaint);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size/2, size/2), size/2 - 2, borderPaint);

    final Paint fillPaint = Paint()
      ..color = isSelected ? AppColors.primaryOrange : (isOpen ? AppColors.success : AppColors.textSecondary)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size/2, size/2), size/2 - 6, fillPaint);

    final img = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }
"""
content = content.replace(old_init, new_init)

# _calculateDistance
old_dist = """  double _calculateDistance(Bazaar bazaar) {
    if (_userPosition == null) return double.infinity;

    const Distance distance = Distance();
    return distance.as(
      LengthUnit.Kilometer,
      LatLng(_userPosition!.latitude, _userPosition!.longitude),
      LatLng(bazaar.latitude, bazaar.longitude),
    );
  }"""
new_dist = """  double _calculateDistance(Bazaar bazaar) {
    if (_userPosition == null) return double.infinity;
    return Geolocator.distanceBetween(
      _userPosition!.latitude,
      _userPosition!.longitude,
      bazaar.latitude,
      bazaar.longitude,
    ) / 1000.0;
  }"""
content = content.replace(old_dist, new_dist)

# centerOnUser
old_center = """      // Center map on user location
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        _defaultZoom,
      );"""
new_center = """      // Center map on user location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          _defaultZoom,
        )
      );"""
content = content.replace(old_center, new_center)

# centerOnBazaar
old_center2 = """  void _centerOnBazaar(Bazaar bazaar) {
    _mapController.move(
      LatLng(bazaar.latitude, bazaar.longitude),
      15.0,
    );
    setState(() => _selectedBazaar = bazaar);
  }"""
new_center2 = """  void _centerOnBazaar(Bazaar bazaar) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(bazaar.latitude, bazaar.longitude),
        15.5,
      )
    );
    setState(() => _selectedBazaar = bazaar);
  }"""
content = content.replace(old_center2, new_center2)

# mapControls zoom in/out
old_zoom_in = """          onTap: () {
            final currentZoom = _mapController.camera.zoom;
            _mapController.move(
              _mapController.camera.center,
              math.min(currentZoom + 1, 18),
            );
          },"""
new_zoom_in = """          onTap: () async {
            final currentZoom = await _mapController?.getZoomLevel() ?? _defaultZoom;
            _mapController?.animateCamera(CameraUpdate.zoomTo(math.min(currentZoom + 1.0, 20.0)));
          },"""
content = content.replace(old_zoom_in, new_zoom_in)

old_zoom_out = """          onTap: () {
            final currentZoom = _mapController.camera.zoom;
            _mapController.move(
              _mapController.camera.center,
              math.max(currentZoom - 1, 5),
            );
          },"""
new_zoom_out = """          onTap: () async {
            final currentZoom = await _mapController?.getZoomLevel() ?? _defaultZoom;
            _mapController?.animateCamera(CameraUpdate.zoomTo(math.max(currentZoom - 1.0, 2.0)));
          },"""
content = content.replace(old_zoom_out, new_zoom_out)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("✅ تم تعديل ملف الخريطة بنجاح!")