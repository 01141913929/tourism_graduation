import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/user_repository.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final _userRepository = UserRepository();
  List<Address> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null) {
      try {
        final addresses = await _userRepository.getAddresses(user.uid);
        if (mounted) {
          setState(() {
            _addresses = addresses;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading addresses: $e');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addAddress(Address address) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null) {
      try {
        await _userRepository.addAddress(user.uid, address);
        await _loadAddresses();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteAddress(String addressId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null) {
      try {
        await _userRepository.deleteAddress(user.uid, addressId);
        await _loadAddresses();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _setDefaultAddress(String addressId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null) {
      try {
        await _userRepository.setDefaultAddress(user.uid, addressId);
        await _loadAddresses();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_forward_ios,
            color: AppColors.textPrimary,
            size: 20,
          ),
        ),
        title: const Text(
          'العناوين',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryOrange),
            )
          : Column(
              children: [
                Expanded(
                  child: _addresses.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _addresses.length,
                          itemBuilder: (context, index) {
                            final address = _addresses[index];
                            return _buildAddressCard(address, index);
                          },
                        ),
                ),

                // Add address button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddAddressSheet(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Iconsax.add, color: AppColors.white),
                        label: const Text(
                          'إضافة عنوان جديد',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.location,
              size: 48,
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد عناوين',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أضف عنوانك الأول للتوصيل السريع',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Address address, int index) {
    final isDefault = address.isDefault;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDefault
            ? Border.all(color: AppColors.primaryOrange, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDefault
                  ? AppColors.primaryOrange.withValues(alpha: 0.05)
                  : AppColors.background.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                // Actions
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'default') {
                      _setDefaultAddress(address.id);
                    } else if (value == 'delete') {
                      _deleteAddress(address.id);
                    }
                  },
                  itemBuilder: (context) => [
                    if (!isDefault)
                      const PopupMenuItem(
                        value: 'default',
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('تعيين كافتراضي'),
                            SizedBox(width: 8),
                            Icon(Iconsax.tick_circle, size: 18),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('تعديل'),
                          SizedBox(width: 8),
                          Icon(Iconsax.edit, size: 18),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'حذف',
                            style: TextStyle(color: AppColors.error),
                          ),
                          const SizedBox(width: 8),
                          Icon(Iconsax.trash, size: 18, color: AppColors.error),
                        ],
                      ),
                    ),
                  ],
                  child: Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                // Label
                Row(
                  children: [
                    if (isDefault)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'افتراضي',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    Text(
                      address.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDefault
                            ? AppColors.primaryOrange.withValues(alpha: 0.1)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        address.label == 'المنزل'
                            ? Iconsax.home
                            : Iconsax.building,
                        color: isDefault
                            ? AppColors.primaryOrange
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Iconsax.location,
                  text: address.addressLine,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Iconsax.building_4,
                  text: '${address.city}، ${address.country}',
                ),
                if (address.postalCode != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Iconsax.sms,
                    text: address.postalCode!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            text,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          icon,
          size: 18,
          color: AppColors.textHint,
        ),
      ],
    );
  }

  void _showAddAddressSheet() {
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    final postalCodeController = TextEditingController();
    String selectedType = 'المنزل';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                    const Spacer(),
                    const Text(
                      'إضافة عنوان جديد',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Address type selection
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setSheetState(() => selectedType = 'العمل'),
                              child: _buildAddressTypeOption(
                                icon: Iconsax.building,
                                label: 'العمل',
                                isSelected: selectedType == 'العمل',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setSheetState(() => selectedType = 'المنزل'),
                              child: _buildAddressTypeOption(
                                icon: Iconsax.home,
                                label: 'المنزل',
                                isSelected: selectedType == 'المنزل',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildFormField(
                        controller: addressController,
                        label: 'العنوان التفصيلي',
                        hint: 'رقم المبنى، اسم الشارع',
                        icon: Iconsax.location,
                      ),
                      _buildFormField(
                        controller: cityController,
                        label: 'المدينة',
                        hint: 'اختر المدينة',
                        icon: Iconsax.building_4,
                      ),
                      _buildFormField(
                        controller: postalCodeController,
                        label: 'الرمز البريدي (اختياري)',
                        hint: 'الرمز البريدي',
                        icon: Iconsax.sms,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            if (addressController.text.isNotEmpty &&
                                cityController.text.isNotEmpty) {
                              final newAddress = Address(
                                id: DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString(),
                                label: selectedType,
                                addressLine: addressController.text,
                                city: cityController.text,
                                postalCode: postalCodeController.text.isNotEmpty
                                    ? postalCodeController.text
                                    : null,
                                isDefault: _addresses.isEmpty,
                              );
                              Navigator.pop(context);
                              _addAddress(newAddress);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'حفظ العنوان',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressTypeOption({
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryOrange.withValues(alpha: 0.1)
            : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primaryOrange : AppColors.divider,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 28,
            color:
                isSelected ? AppColors.primaryOrange : AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? AppColors.primaryOrange
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryOrange,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: AppColors.primaryOrange, width: 2),
          ),
          filled: true,
          fillColor: AppColors.white,
        ),
      ),
    );
  }
}
