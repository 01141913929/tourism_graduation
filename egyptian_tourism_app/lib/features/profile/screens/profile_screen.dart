import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../models/models.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/artifact_repository.dart';
import '../../../repositories/order_repository.dart';
import 'favorites_screen.dart';
import 'my_orders_screen.dart';
import 'personal_info_screen.dart';
import 'addresses_screen.dart';
import 'payment_methods_screen.dart';
import 'messages_list_screen.dart';
import 'help_center_screen.dart';

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
    await Future.wait([
      _loadRecentArtifacts(),
      _loadOrdersCount(),
    ]);
  }

  Future<void> _loadRecentArtifacts() async {
    try {
      final artifacts = await _artifactRepository.getArtifacts();
      if (mounted) {
        setState(() {
          _recentArtifacts = artifacts.take(4).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading artifacts: $e');
    }
  }

  Future<void> _loadOrdersCount() async {
    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.userId != null) {
        final orders =
            await _orderRepository.getUserOrders(authProvider.userId!);
        if (mounted) {
          setState(() {
            _ordersCount = orders.length;
            _favoritesCount = authProvider.user?.favoriteProductIds.length ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading orders count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverToBoxAdapter(
            child: _buildProfileHeader(context),
          ),

          // Stats Cards
          SliverToBoxAdapter(
            child: _buildStatsCards(),
          ),

          // Recent Visits
          SliverToBoxAdapter(
            child: _buildRecentVisits(context),
          ),

          // Menu Items
          SliverToBoxAdapter(
            child: _buildMenuSection(context),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryOrange, Color(0xFFD4651F)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Decorative elements
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: 0,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Iconsax.setting_2,
                            color: AppColors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const Text(
                        'الحساب الشخصي',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Iconsax.notification,
                            color: AppColors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Avatar and info
                  Row(
                    children: [
                      // Edit button
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PersonalInfoScreen(),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_back_ios,
                              size: 14,
                              color: AppColors.white.withValues(alpha: 0.8),
                            ),
                            Text(
                              'تعديل',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Info
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          final userName =
                              authProvider.user?.name ?? 'المستخدم';
                          final initials = userName.isNotEmpty
                              ? userName.substring(0, 1)
                              : 'م';
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 120),
                                    child: Text(
                                      userName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.gold.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'عضو ذهبي',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.gold,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Iconsax.crown5,
                                          size: 14,
                                          color: AppColors.gold,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              // Avatar
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.black
                                          .withValues(alpha: 0.2),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryOrange,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildStatItem(
              icon: Iconsax.heart5,
              value: '$_favoritesCount',
              label: 'المفضلة',
              color: AppColors.error,
            ),
            _buildStatDivider(),
            _buildStatItem(
              icon: Iconsax.box,
              value: '$_ordersCount',
              label: 'الطلبات',
              color: AppColors.primaryOrange,
            ),
            _buildStatDivider(),
            _buildStatItem(
              icon: Iconsax.location,
              value: '${_recentArtifacts.length}',
              label: 'الزيارات',
              color: AppColors.secondaryTeal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 50,
      color: AppColors.divider,
    );
  }

  Widget _buildRecentVisits(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {},
                child: const Row(
                  children: [
                    Icon(
                      Icons.arrow_back_ios,
                      size: 14,
                      color: AppColors.primaryOrange,
                    ),
                    Text(
                      'عرض الكل',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Text(
                    'آخر الزيارات',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Iconsax.clock,
                    color: AppColors.primaryOrange,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              reverse: true,
              itemCount: 4,
              itemBuilder: (context, index) {
                final artifact = _recentArtifacts.isNotEmpty
                    ? _recentArtifacts[index % _recentArtifacts.length]
                    : null;
                if (artifact == null) {
                  return const SizedBox();
                }
                return Container(
                  width: 110,
                  margin: const EdgeInsets.only(left: 12),
                  child: Column(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: artifact.imageUrl,
                                  width: 110,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryOrange,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 10,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        artifact.nameAr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: AppColors.white,
      child: Column(
        children: [
          _buildMenuItem(
            context: context,
            icon: Iconsax.heart,
            title: 'المفضلة',
            subtitle: 'التحف والمنتجات المحفوظة',
            badgeCount: 12,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FavoritesScreen(),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            context: context,
            icon: Iconsax.box,
            title: 'طلباتي',
            subtitle: '2 طلب قيد التنفيذ',
            badgeCount: 2,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyOrdersScreen(),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            context: context,
            icon: Iconsax.user,
            title: 'معلوماتي الشخصية',
            subtitle: 'تعديل البيانات الشخصية',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PersonalInfoScreen(),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            context: context,
            icon: Iconsax.location,
            title: 'العناوين',
            subtitle: '2 عنوان محفوظ',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddressesScreen(),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            context: context,
            icon: Iconsax.card,
            title: 'وسائل الدفع',
            subtitle: 'بطاقات الائتمان والمحافظ',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PaymentMethodsScreen(),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            context: context,
            icon: Iconsax.messages,
            title: 'رسائلي',
            subtitle: 'محادثات مع البازارات',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MessagesListScreen(),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            context: context,
            icon: Iconsax.message_question,
            title: 'مركز المساعدة',
            subtitle: 'الأسئلة الشائعة والدعم',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HelpCenterScreen(),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            context: context,
            icon: Iconsax.logout,
            title: 'تسجيل الخروج',
            subtitle: '',
            isLogout: true,
            onTap: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int? badgeCount,
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(
              Icons.arrow_back_ios,
              color: AppColors.textHint,
              size: 16,
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isLogout ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isLogout
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isLogout ? AppColors.error : AppColors.textSecondary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: AppColors.divider,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.logout,
                color: AppColors.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'تسجيل الخروج',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'هل أنت متأكد من تسجيل الخروج؟',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: AppColors.divider),
                    ),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context); // Close the dialog
                      final authProvider = context.read<AuthProvider>();
                      await authProvider.signOut();
                      if (context.mounted) {
                        // Navigate to login screen and clear the navigation stack
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login',
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'خروج',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
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
}
