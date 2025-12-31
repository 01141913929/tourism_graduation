import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../core/constants/colors.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  StreamSubscription? _userSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  /// إعداد Realtime Listener للتحديث الفوري عند موافقة/رفض الطلب
  void _setupRealtimeListener() {
    final authProvider = context.read<BazaarAuthProvider>();
    final userId = authProvider.userId;

    if (userId == null) return;

    // الاستماع لتغييرات وثيقة المستخدم في Firestore
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted || !snapshot.exists) return;

      final data = snapshot.data()!;
      final applicationStatus = data['applicationStatus'] as String?;

      if (applicationStatus == 'approved') {
        // تمت الموافقة - انتقل للـ Dashboard
        authProvider.refreshUserData().then((_) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          }
        });
      } else if (applicationStatus == 'rejected') {
        // تم الرفض - تحديث الشاشة لعرض سبب الرفض
        authProvider.refreshUserData().then((_) {
          if (mounted) setState(() {});
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<BazaarAuthProvider>(
        builder: (context, auth, _) {
          if (auth.isRejected) {
            return _buildRejectedView(auth);
          }
          return _buildPendingView();
        },
      ),
    );
  }

  Widget _buildPendingView() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.timer_1,
                size: 80,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'طلبك قيد المراجعة',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'يتم الآن مراجعة طلب تسجيل البازار الخاص بك.\nسيتم إخطارك فور الموافقة على طلبك.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),

            // Status timeline
            Container(
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
              child: Column(
                children: [
                  _buildStatusStep(
                    icon: Iconsax.tick_circle5,
                    title: 'تم استلام طلبك',
                    subtitle: 'تم إرسال طلبك بنجاح',
                    isCompleted: true,
                    isLast: false,
                  ),
                  _buildStatusStep(
                    icon: Iconsax.timer_1,
                    title: 'قيد المراجعة',
                    subtitle: 'يتم مراجعة بيانات البازار',
                    isCompleted: false,
                    isActive: true,
                    isLast: false,
                  ),
                  _buildStatusStep(
                    icon: Iconsax.tick_circle,
                    title: 'الموافقة',
                    subtitle: 'انتظر الموافقة على طلبك',
                    isCompleted: false,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Refresh button
            TextButton.icon(
              onPressed: () async {
                final authProvider = context.read<BazaarAuthProvider>();
                await authProvider.refreshUserData();
                if (authProvider.isApprovedBazaarOwner && mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                  );
                }
              },
              icon: const Icon(Iconsax.refresh),
              label: const Text('تحديث الحالة'),
            ),
            const Spacer(),

            // Logout button
            TextButton(
              onPressed: () async {
                await context.read<BazaarAuthProvider>().signOut();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
              child: Text(
                'تسجيل الخروج',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedView(BazaarAuthProvider auth) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.close_circle,
                size: 80,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'تم رفض طلبك',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'نأسف، تم رفض طلب تسجيل البازار الخاص بك.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            if (auth.user?.applicationRejectionReason != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'سبب الرفض:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auth.user!.applicationRejectionReason!,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  await context.read<BazaarAuthProvider>().signOut();
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('العودة لتسجيل الدخول'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
    bool isActive = false,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success
                    : isActive
                        ? AppColors.warning
                        : AppColors.divider,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isCompleted || isActive
                    ? AppColors.white
                    : AppColors.textHint,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? AppColors.success : AppColors.divider,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCompleted || isActive
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (!isLast) const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
