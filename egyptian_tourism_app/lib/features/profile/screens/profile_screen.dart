import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../models/models.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/artifact_repository.dart';
import '../../../repositories/order_repository.dart';
import '../../../providers/language_provider.dart';
import 'favorites_screen.dart';
import 'my_orders_screen.dart';
import 'personal_info_screen.dart';
import 'addresses_screen.dart';
import 'payment_methods_screen.dart';
import 'messages_list_screen.dart';
import 'help_center_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'my_reviews_screen.dart';
import '../../artifacts/screens/artifacts_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ArtifactRepository _artifactRepository = ArtifactRepository();
  final OrderRepository _orderRepository = OrderRepository();
  List<Artifact> _recentArtifacts = [];
  int _ordersCount = 0;
  int _favoritesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadRecentArtifacts(), _loadOrdersCount()]);
  }

  Future<void> _loadRecentArtifacts() async {
    try {
      final artifacts = await _artifactRepository.getArtifacts();
      if (mounted)
        setState(() => _recentArtifacts = artifacts.take(4).toList());
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _loadOrdersCount() async {
    try {
      final auth = context.read<AuthProvider>();
      if (auth.userId != null) {
        final orders = await _orderRepository.getUserOrders(auth.userId!);
        if (mounted) {
          setState(() {
            _ordersCount = orders.length;
            _favoritesCount = auth.user?.favoriteProductIds.length ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildTopBar(),
                _buildProfileCard(),
                const SizedBox(height: 24),
                _buildQuickStats(),
                const SizedBox(height: 24),
                _buildRecentActivity(),
                const SizedBox(height: 24),
                _buildMenuSections(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          _iconButton(
              Iconsax.setting_2,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()))),
          const Spacer(),
          Text(
            AppStrings.profile,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const Spacer(),
          _iconButton(
              Iconsax.notification,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen())),
              showBadge: true),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap,
      {bool showBadge = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 22, color: AppColors.textPrimary),
            if (showBadge)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.error, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final name =
            auth.user?.name ?? (AppStrings.isArabic ? 'المستخدم' : 'User');
        final email = auth.user?.email ?? '';
        final initials = name.isNotEmpty
            ? name[0].toUpperCase()
            : (AppStrings.isArabic ? 'م' : 'U');

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.pharaohBlue, Color(0xFF2C5282)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.pharaohBlue.withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Edit Button
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PersonalInfoScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Iconsax.edit_2,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(AppStrings.edit,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Info
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7)),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Avatar
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.pharaohBlue),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Membership
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.isArabic
                          ? 'عضوية ذهبية نشطة'
                          : 'Active Gold Membership',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9)),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Iconsax.crown5, size: 18, color: Colors.amber),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _statCard(Iconsax.heart5, '$_favoritesCount', AppStrings.favorites,
              AppColors.primaryOrange, () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()));
          }),
          const SizedBox(width: 12),
          _statCard(
              Iconsax.box, '$_ordersCount', AppStrings.orders, AppColors.gold,
              () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MyOrdersScreen()));
          }),
          const SizedBox(width: 12),
          _statCard(
              Iconsax.location,
              '${_recentArtifacts.length}',
              AppStrings.isArabic ? 'الزيارات' : 'Visits',
              AppColors.secondaryTeal,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ArtifactsScreen()))),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color,
      VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w900, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF888888)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    if (_recentArtifacts.isEmpty) return const SizedBox();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ArtifactsScreen())),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_ios,
                        size: 12, color: AppColors.primaryOrange),
                    const SizedBox(width: 4),
                    Text(AppStrings.seeAll,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryOrange)),
                  ],
                ),
              ),
              const Spacer(),
              Text(AppStrings.isArabic ? 'النشاط الأخير' : 'Recent Activity',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: _recentArtifacts.length,
            itemBuilder: (context, index) {
              final artifact = _recentArtifacts[index];
              return Container(
                width: 100,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CachedNetworkImage(
                            imageUrl: artifact.imageUrl, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      artifact.nameAr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSections() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.isArabic ? 'الحساب' : 'Account',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          _menuCard([
            _menuItem(
                Iconsax.user,
                AppStrings.personalInfo,
                const Color(0xFF667eea),
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PersonalInfoScreen()))),
            _menuItem(
                Iconsax.location,
                AppStrings.addresses,
                const Color(0xFF4ecdc4),
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddressesScreen()))),
            _menuItem(
                Iconsax.card,
                AppStrings.paymentMethods,
                const Color(0xFFf093fb),
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PaymentMethodsScreen()))),
          ]),
          const SizedBox(height: 20),
          Text(AppStrings.isArabic ? 'التواصل' : 'Communication',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          _menuCard([
            _menuItem(
                Iconsax.messages_3,
                AppStrings.isArabic ? 'رسائلي' : 'Messages',
                AppColors.pharaohBlue,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MessagesListScreen())),
                badge: 3),
            _menuItem(
                Iconsax.message_question,
                AppStrings.helpCenter,
                AppColors.gold,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const HelpCenterScreen()))),
          ]),
          const SizedBox(height: 20),
          Text(AppStrings.isArabic ? 'المزيد' : 'More',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          _menuCard([
            _menuItem(
                Iconsax.star,
                AppStrings.isArabic ? 'تقييماتي' : 'My Reviews',
                const Color(0xFFf8b500),
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MyReviewsScreen()))),
            _menuItem(
                Iconsax.heart_edit,
                AppStrings.isArabic ? 'قيّم التطبيق' : 'Rate App',
                const Color(0xFFe17055),
                () => _showRateAppDialog()),
            _menuItem(Iconsax.info_circle, AppStrings.aboutUs,
                const Color(0xFF00cec9), () => _showAboutDialog()),
            _menuItem(Iconsax.logout, AppStrings.logout,
                const Color(0xFFff7675), () => _showLogoutDialog(),
                isDestructive: true),
          ]),
        ],
      ),
    );
  }

  Widget _menuCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          return Column(
            children: [
              items[index],
              if (index < items.length - 1)
                Divider(
                    height: 1,
                    indent: 64,
                    endIndent: 16,
                    color: Colors.grey.shade200),
            ],
          );
        }),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, Color color, VoidCallback onTap,
      {int? badge, bool isDestructive = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.arrow_back_ios, size: 14, color: Colors.grey.shade400),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(10)),
                  child: Text('$badge',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ],
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? color : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFff7675).withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Iconsax.logout,
                  size: 28, color: Color(0xFFff7675)),
            ),
            const SizedBox(height: 20),
            Text(AppStrings.logout,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(AppStrings.logoutConfirm,
                style: const TextStyle(fontSize: 14, color: Color(0xFF888888))),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(AppStrings.cancel,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      context.read<AuthProvider>().signOut();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(AppStrings.logout,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRateAppDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFf8b500).withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child:
                  const Icon(Iconsax.star1, size: 32, color: Color(0xFFf8b500)),
            ),
            const SizedBox(height: 20),
            Text(AppStrings.isArabic ? 'قيّم التطبيق' : 'Rate App',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
                AppStrings.isArabic
                    ? 'رأيك يهمنا! ساعدنا في تحسين التطبيق'
                    : 'Your opinion matters! Help us improve',
                style: const TextStyle(fontSize: 14, color: Color(0xFF888888))),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  5,
                  (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Iconsax.star1,
                            size: 36,
                            color: i < 4
                                ? const Color(0xFFf8b500)
                                : Colors.grey.shade300),
                      )),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFf8b500),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                    AppStrings.isArabic ? 'إرسال التقييم' : 'Submit Rating',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00cec9), Color(0xFF0984e3)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Iconsax.shop, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text('سوق مصر',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('الإصدار 1.0.0',
                style: TextStyle(fontSize: 14, color: Color(0xFF888888))),
            const SizedBox(height: 16),
            const Text(
              'تطبيق متخصص في عرض وبيع التحف والهدايا المصرية الأصيلة. اكتشف روائع الحضارة الفرعونية واقتني قطعاً فريدة من تاريخ مصر العريق.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Color(0xFF666666), height: 1.6),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00cec9),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('حسناً',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
