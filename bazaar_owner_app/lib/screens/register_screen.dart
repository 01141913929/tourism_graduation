import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/auth_provider.dart';
import '../core/constants/colors.dart';
import 'dashboard_screen.dart';
import 'pending_approval_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;

  // Personal info
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Bazaar info
  final _bazaarNameController = TextEditingController();
  final _bazaarDescController = TextEditingController();
  final _bazaarAddressController = TextEditingController();
  String _selectedGovernorate = 'الأقصر';

  final List<String> _governorates = [
    'الأقصر',
    'أسوان',
    'القاهرة',
    'الجيزة',
    'الإسكندرية',
    'شرم الشيخ',
    'الغردقة',
    'سيناء',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _bazaarNameController.dispose();
    _bazaarDescController.dispose();
    _bazaarAddressController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (!_validatePersonalInfo()) return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _validatePersonalInfo() {
    if (_nameController.text.isEmpty) {
      _showError('يرجى إدخال الاسم');
      return false;
    }
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showError('يرجى إدخال بريد إلكتروني صحيح');
      return false;
    }
    if (_phoneController.text.isEmpty) {
      _showError('يرجى إدخال رقم الهاتف');
      return false;
    }
    if (_passwordController.text.length < 6) {
      _showError('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> _register() async {
    if (_bazaarNameController.text.isEmpty) {
      _showError('يرجى إدخال اسم البازار');
      return;
    }
    if (_bazaarDescController.text.isEmpty) {
      _showError('يرجى إدخال وصف البازار');
      return;
    }
    if (_bazaarAddressController.text.isEmpty) {
      _showError('يرجى إدخال عنوان البازار');
      return;
    }

    final authProvider = context.read<BazaarAuthProvider>();
    final success = await authProvider.registerBazaarOwner(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      bazaarName: _bazaarNameController.text.trim(),
      bazaarDescription: _bazaarDescController.text.trim(),
      bazaarAddress: _bazaarAddressController.text.trim(),
      governorate: _selectedGovernorate,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
      );
    } else {
      _showError(authProvider.error ?? 'حدث خطأ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تسجيل بازار جديد'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 20),
          onPressed: () {
            if (_currentPage == 0) {
              Navigator.pop(context);
            } else {
              _previousPage();
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStepIndicator(0, 'البيانات الشخصية'),
                Expanded(
                  child: Container(
                    height: 2,
                    color: _currentPage >= 1
                        ? AppColors.primary
                        : AppColors.divider,
                  ),
                ),
                _buildStepIndicator(1, 'بيانات البازار'),
              ],
            ),
          ),

          // Form pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [_buildPersonalInfoPage(), _buildBazaarInfoPage()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentPage >= step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.divider,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive && _currentPage > step
                ? const Icon(Icons.check, size: 18, color: AppColors.white)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? AppColors.white : AppColors.textHint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? AppColors.textPrimary : AppColors.textHint,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'البيانات الشخصية',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أدخل بياناتك الشخصية للتسجيل كصاحب بازار',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          _buildTextField(
            controller: _nameController,
            label: 'الاسم الكامل',
            icon: Iconsax.user,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'البريد الإلكتروني',
            icon: Iconsax.sms,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'رقم الهاتف',
            icon: Iconsax.call,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            label: 'كلمة المرور',
            icon: Iconsax.lock,
            obscureText: _obscurePassword,
            textDirection: TextDirection.ltr,
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Iconsax.eye_slash : Iconsax.eye),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'التالي',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_back_ios, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBazaarInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'بيانات البازار',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أدخل معلومات البازار الخاص بك',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          _buildTextField(
            controller: _bazaarNameController,
            label: 'اسم البازار',
            icon: Iconsax.shop,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _bazaarDescController,
            label: 'وصف البازار',
            icon: Iconsax.document_text,
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Governorate dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedGovernorate,
                isExpanded: true,
                icon: const Icon(Iconsax.arrow_down_1),
                items: _governorates.map((g) {
                  return DropdownMenuItem(value: g, child: Text(g));
                }).toList(),
                onChanged: (value) {
                  if (value != null)
                    setState(() => _selectedGovernorate = value);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _bazaarAddressController,
            label: 'عنوان البازار التفصيلي',
            icon: Iconsax.location,
            maxLines: 2,
          ),
          const SizedBox(height: 32),

          Consumer<BazaarAuthProvider>(
            builder: (context, auth, _) {
              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'إرسال طلب التسجيل',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '⏳ سيتم مراجعة طلبك خلال 24-48 ساعة',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
    Widget? suffixIcon,
    TextDirection? textDirection,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      textDirection: textDirection,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
