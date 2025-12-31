import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../models/bazaar_model.dart';
import '../../../repositories/bazaar_repository.dart';

class InteractiveMapScreen extends StatefulWidget {
  const InteractiveMapScreen({super.key});

  @override
  State<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends State<InteractiveMapScreen>
    with TickerProviderStateMixin {
  final BazaarRepository _bazaarRepository = BazaarRepository();
  final MapController _mapController = MapController();

  List<Bazaar> _bazaars = [];
  List<Bazaar> _filteredBazaars = [];
  bool _isLoading = true;
  Bazaar? _selectedBazaar;
  Position? _userPosition;
  bool _isLocating = false;
  bool _showOnlyOpen = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Default center: Luxor, Egypt
  static const LatLng _defaultCenter = LatLng(25.6872, 32.6396);
  static const double _defaultZoom = 12.0;

  @override
  void initState() {
    super.initState();
    _loadBazaars();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadBazaars() async {
    try {
      final bazaars = await _bazaarRepository.getBazaars();
      setState(() {
        _bazaars = bazaars;
        _filteredBazaars = bazaars;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLocating = false);
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLocating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLocating = false);
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userPosition = position;
        _isLocating = false;
      });

      // Center map on user location
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        _defaultZoom,
      );

      _applyFilters(); // Recalculate distances
    } catch (e) {
      setState(() => _isLocating = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredBazaars = _bazaars.where((bazaar) {
        // Apply open filter
        if (_showOnlyOpen && !bazaar.isOpen) return false;

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return bazaar.nameAr.toLowerCase().contains(query) ||
              bazaar.nameEn.toLowerCase().contains(query) ||
              bazaar.address.toLowerCase().contains(query);
        }

        return true;
      }).toList();

      // Sort by distance if user location available
      if (_userPosition != null) {
        _filteredBazaars.sort((a, b) {
          final distA = _calculateDistance(a);
          final distB = _calculateDistance(b);
          return distA.compareTo(distB);
        });
      }
    });
  }

  double _calculateDistance(Bazaar bazaar) {
    if (_userPosition == null) return double.infinity;

    const Distance distance = Distance();
    return distance.as(
      LengthUnit.Kilometer,
      LatLng(_userPosition!.latitude, _userPosition!.longitude),
      LatLng(bazaar.latitude, bazaar.longitude),
    );
  }

  String _formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).round()} متر';
    }
    return '${km.toStringAsFixed(1)} كم';
  }

  Future<void> _openGoogleMapsNavigation(Bazaar bazaar) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${bazaar.latitude},${bazaar.longitude}&travelmode=driving',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن فتح خرائط جوجل'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _centerOnBazaar(Bazaar bazaar) {
    _mapController.move(
      LatLng(bazaar.latitude, bazaar.longitude),
      15.0,
    );
    setState(() => _selectedBazaar = bazaar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main Map
          _buildMap(),

          // Top Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: _buildSearchBar(),
          ),

          // Filter Chips
          Positioned(
            top: MediaQuery.of(context).padding.top + 72,
            left: 16,
            right: 16,
            child: _buildFilterChips(),
          ),

          // Map Controls
          Positioned(
            bottom: 280,
            right: 16,
            child: _buildMapControls(),
          ),

          // Bottom Sheet
          _buildDraggableBottomSheet(),

          // Selected Bazaar Popup
          if (_selectedBazaar != null)
            Positioned(
              bottom: 320,
              left: 16,
              right: 16,
              child: _buildBazaarPopup(_selectedBazaar!),
            ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: const Color.fromRGBO(0, 0, 0, 0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryOrange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _defaultCenter,
        initialZoom: _defaultZoom,
        minZoom: 5,
        maxZoom: 18,
        onTap: (_, __) {
          setState(() => _selectedBazaar = null);
        },
      ),
      children: [
        // OpenStreetMap Tile Layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.egyptian_tourism_app',
          maxZoom: 19,
        ),

        // User Location Marker
        if (_userPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                  _userPosition!.latitude,
                  _userPosition!.longitude,
                ),
                width: 30,
                height: 30,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.info,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(33, 150, 243, 0.4),
                        blurRadius: 10,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),

        // Bazaar Markers
        MarkerLayer(
          markers: _filteredBazaars.map((bazaar) {
            final isSelected = _selectedBazaar?.id == bazaar.id;
            return Marker(
              point: LatLng(bazaar.latitude, bazaar.longitude),
              width: isSelected ? 50 : 44,
              height: isSelected ? 60 : 54,
              child: GestureDetector(
                onTap: () => _centerOnBazaar(bazaar),
                child: _buildBazaarMarker(bazaar, isSelected),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBazaarMarker(Bazaar bazaar, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryOrange
                : (bazaar.isOpen ? AppColors.success : AppColors.textSecondary),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.white,
              width: isSelected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isSelected
                        ? AppColors.primaryOrange
                        : (bazaar.isOpen
                            ? AppColors.success
                            : AppColors.textSecondary))
                    .withOpacity(0.4),
                blurRadius: isSelected ? 12 : 8,
                spreadRadius: isSelected ? 2 : 1,
              ),
            ],
          ),
          child: Icon(
            Icons.store_rounded,
            color: AppColors.white,
            size: isSelected ? 22 : 18,
          ),
        ),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryOrange
                : (bazaar.isOpen ? AppColors.success : AppColors.textSecondary),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: 'ابحث عن بازار...',
          hintStyle: const TextStyle(
            color: AppColors.textHint,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textSecondary,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _applyFilters();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: 'المفتوح فقط',
            icon: Icons.access_time,
            isSelected: _showOnlyOpen,
            onTap: () {
              setState(() => _showOnlyOpen = !_showOnlyOpen);
              _applyFilters();
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'الكل (${_bazaars.length})',
            icon: Icons.store,
            isSelected: !_showOnlyOpen,
            onTap: () {
              setState(() => _showOnlyOpen = false);
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryOrange : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Column(
      children: [
        // Zoom In
        _buildControlButton(
          icon: Icons.add,
          onTap: () {
            final currentZoom = _mapController.camera.zoom;
            _mapController.move(
              _mapController.camera.center,
              math.min(currentZoom + 1, 18),
            );
          },
        ),
        const SizedBox(height: 8),
        // Zoom Out
        _buildControlButton(
          icon: Icons.remove,
          onTap: () {
            final currentZoom = _mapController.camera.zoom;
            _mapController.move(
              _mapController.camera.center,
              math.max(currentZoom - 1, 5),
            );
          },
        ),
        const SizedBox(height: 16),
        // My Location
        _buildControlButton(
          icon: _isLocating ? Icons.hourglass_empty : Icons.my_location,
          color: AppColors.info,
          onTap: _isLocating ? null : _getCurrentLocation,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    Color? color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color ?? AppColors.textPrimary,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildBazaarPopup(Bazaar bazaar) {
    final distance = _userPosition != null ? _calculateDistance(bazaar) : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              // Close button
              GestureDetector(
                onTap: () => setState(() => _selectedBazaar = null),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              // Name and status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    bazaar.nameAr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: bazaar.isOpen
                              ? const Color.fromRGBO(76, 175, 80, 0.1)
                              : const Color.fromRGBO(229, 57, 53, 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          bazaar.isOpen ? 'مفتوح' : 'مغلق',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: bazaar.isOpen
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ),
                      if (distance != null) ...[
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatDistance(distance),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.store_rounded,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Info Row
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.access_time,
                  label: bazaar.workingHours,
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: AppColors.divider,
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.shopping_bag_outlined,
                  label: '${bazaar.productIds.length} منتج',
                ),
              ),
              if (bazaar.rating > 0) ...[
                Container(
                  width: 1,
                  height: 30,
                  color: AppColors.divider,
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.star,
                    label: bazaar.rating.toStringAsFixed(1),
                    iconColor: AppColors.gold,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              // Navigate Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openGoogleMapsNavigation(bazaar),
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('اذهب للبازار'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Browse Products Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to bazaar products
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تصفح منتجات ${bazaar.nameAr}'),
                        backgroundColor: AppColors.primaryOrange,
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: const Text('تصفح المنتجات'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryOrange,
                    side: const BorderSide(color: AppColors.primaryOrange),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    Color? iconColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          icon,
          size: 14,
          color: iconColor ?? AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildDraggableBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.12,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_filteredBazaars.length} بازار',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Text(
                      'البازارات القريبة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryOrange,
                        ),
                      )
                    : _filteredBazaars.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredBazaars.length,
                            itemBuilder: (context, index) {
                              return _buildBazaarListItem(
                                  _filteredBazaars[index]);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.store_mall_directory_outlined,
            size: 64,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد بازارات',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _searchQuery.isNotEmpty
                ? 'جرب البحث بكلمة أخرى'
                : 'لا توجد بازارات متاحة حالياً',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBazaarListItem(Bazaar bazaar) {
    final distance = _userPosition != null ? _calculateDistance(bazaar) : null;

    return GestureDetector(
      onTap: () => _centerOnBazaar(bazaar),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _selectedBazaar?.id == bazaar.id
              ? AppColors.primaryOrange.withOpacity(0.08)
              : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: _selectedBazaar?.id == bazaar.id
              ? Border.all(color: AppColors.primaryOrange.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            // Status and Navigate Button
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: bazaar.isOpen
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    bazaar.isOpen ? 'مفتوح' : 'مغلق',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color:
                          bazaar.isOpen ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _openGoogleMapsNavigation(bazaar),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.directions,
                      color: AppColors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Name and Details
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  bazaar.nameAr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (distance != null) ...[
                      Text(
                        _formatDistance(distance),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '${bazaar.productIds.length} منتج',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.store_rounded,
                color: AppColors.primaryOrange,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
