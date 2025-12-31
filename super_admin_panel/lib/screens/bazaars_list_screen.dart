import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../core/constants/colors.dart';
import '../providers/admin_data_provider.dart';
import '../models/bazaar_model.dart';

/// شاشة قائمة البازارات
class BazaarsListScreen extends StatefulWidget {
  const BazaarsListScreen({super.key});

  @override
  State<BazaarsListScreen> createState() => _BazaarsListScreenState();
}

class _BazaarsListScreenState extends State<BazaarsListScreen> {
  String _searchQuery = '';
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            color: AppColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🏪 إدارة البازارات',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'عرض وإدارة جميع البازارات المسجلة في المنصة',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Search and filters
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'بحث عن بازار...',
                          prefixIcon: const Icon(Iconsax.search_normal),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterStatus,
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('الكل')),
                            DropdownMenuItem(
                              value: 'active',
                              child: Text('نشط'),
                            ),
                            DropdownMenuItem(
                              value: 'inactive',
                              child: Text('معطل'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _filterStatus = value ?? 'all');
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bazaars list
          Expanded(
            child: Consumer<AdminDataProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final filteredBazaars = provider.allBazaars.where((bazaar) {
                  final matchesSearch = bazaar.nameAr.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  );
                  final matchesFilter =
                      _filterStatus == 'all' ||
                      (_filterStatus == 'active' && bazaar.isVerified) ||
                      (_filterStatus == 'inactive' && !bazaar.isVerified);
                  return matchesSearch && matchesFilter;
                }).toList();

                if (filteredBazaars.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.shop, size: 64, color: AppColors.textHint),
                        const SizedBox(height: 16),
                        const Text(
                          'لا توجد بازارات',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: filteredBazaars.length,
                  itemBuilder: (context, index) {
                    final bazaar = filteredBazaars[index];
                    return _buildBazaarCard(bazaar, provider);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBazaarCard(Bazaar bazaar, AdminDataProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bazaar image placeholder
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.shop, size: 40, color: AppColors.primary),
          ),
          const SizedBox(width: 20),

          // Bazaar info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        bazaar.nameAr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: bazaar.isVerified
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            bazaar.isVerified
                                ? Iconsax.tick_circle
                                : Iconsax.close_circle,
                            color: bazaar.isVerified
                                ? AppColors.success
                                : AppColors.error,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            bazaar.isVerified ? 'نشط' : 'معطل',
                            style: TextStyle(
                              color: bazaar.isVerified
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Iconsax.location, size: 16, color: AppColors.textHint),
                    const SizedBox(width: 6),
                    Text(
                      '${bazaar.governorate} - ${bazaar.address}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Iconsax.call, size: 16, color: AppColors.textHint),
                    const SizedBox(width: 6),
                    Text(
                      bazaar.phone,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Icon(Icons.star, size: 16, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      '${bazaar.rating.toStringAsFixed(1)} (${bazaar.reviewsCount})',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        // View details
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      icon: const Icon(Iconsax.eye, size: 16),
                      label: const Text('عرض'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final success = await provider.toggleBazaarVerification(
                          bazaar.id,
                          !bazaar.isVerified,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? (bazaar.isVerified
                                          ? 'تم إلغاء تفعيل البازار'
                                          : 'تم تفعيل البازار')
                                    : 'حدث خطأ',
                              ),
                              backgroundColor: success
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bazaar.isVerified
                            ? AppColors.error
                            : AppColors.success,
                        foregroundColor: AppColors.white,
                      ),
                      icon: Icon(
                        bazaar.isVerified
                            ? Iconsax.close_circle
                            : Iconsax.tick_circle,
                        size: 16,
                      ),
                      label: Text(
                        bazaar.isVerified ? 'إلغاء التفعيل' : 'تفعيل',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
