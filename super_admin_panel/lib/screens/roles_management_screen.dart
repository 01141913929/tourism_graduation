import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';

/// شاشة إدارة الأدوار والصلاحيات
class RolesManagementScreen extends StatefulWidget {
  const RolesManagementScreen({super.key});

  @override
  State<RolesManagementScreen> createState() => _RolesManagementScreenState();
}

class _RolesManagementScreenState extends State<RolesManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _admins = [];
  bool _isLoading = true;

  // Available roles
  static const List<Map<String, dynamic>> _roles = [
    {
      'id': 'superAdmin',
      'nameAr': 'مدير عام',
      'nameEn': 'Super Admin',
      'icon': Iconsax.crown_1,
      'color': Color(0xFFD4A574),
      'permissions': ['all'],
      'description': 'صلاحيات كاملة على النظام',
    },
    {
      'id': 'moderator',
      'nameAr': 'مشرف',
      'nameEn': 'Moderator',
      'icon': Iconsax.shield_tick,
      'color': Color(0xFF3B82F6),
      'permissions': ['bazaars', 'products', 'reviews', 'complaints'],
      'description': 'إدارة البازارات والمنتجات والتقييمات',
    },
    {
      'id': 'support',
      'nameAr': 'دعم فني',
      'nameEn': 'Support',
      'icon': Iconsax.message_question,
      'color': Color(0xFF10B981),
      'permissions': ['complaints', 'messages', 'users_read'],
      'description': 'التعامل مع الشكاوى والرسائل',
    },
    {
      'id': 'accountant',
      'nameAr': 'محاسب',
      'nameEn': 'Accountant',
      'icon': Iconsax.calculator,
      'color': Color(0xFF8B5CF6),
      'permissions': ['reports', 'orders_read', 'commissions'],
      'description': 'التقارير المالية والعمولات',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: true)
          .get();

      _admins = snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();
    } catch (e) {
      debugPrint('Error loading admins: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddAdminDialog() {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    String selectedRole = 'moderator';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Iconsax.user_add, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('إضافة مسؤول جديد'),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'الاسم',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('الدور:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...(_roles.where((r) => r['id'] != 'superAdmin').map(
                      (role) => RadioListTile<String>(
                        value: role['id'] as String,
                        groupValue: selectedRole,
                        onChanged: (v) =>
                            setDialogState(() => selectedRole = v!),
                        title: Text(role['nameAr'] as String),
                        subtitle: Text(
                          role['description'] as String,
                          style: const TextStyle(fontSize: 11),
                        ),
                        secondary: Icon(role['icon'] as IconData,
                            color: role['color'] as Color),
                        contentPadding: EdgeInsets.zero,
                      ),
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (emailController.text.isEmpty ||
                    nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى ملء جميع الحقول')),
                  );
                  return;
                }
                Navigator.pop(context);
                await _addAdmin(
                  email: emailController.text,
                  name: nameController.text,
                  role: selectedRole,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addAdmin({
    required String email,
    required String name,
    required String role,
  }) async {
    try {
      // Check if user exists
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        // Create new admin user
        await _firestore.collection('users').add({
          'email': email,
          'name': name,
          'role': role,
          'adminRole': role,
          'isAdmin': true,
          'createdAt': DateTime.now().toIso8601String(),
        });
      } else {
        // Update existing user
        await _firestore
            .collection('users')
            .doc(userQuery.docs.first.id)
            .update({
          'adminRole': role,
          'isAdmin': true,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إضافة المسؤول بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadAdmins();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _updateRole(String adminId, String newRole) async {
    try {
      await _firestore.collection('users').doc(adminId).update({
        'adminRole': newRole,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم تحديث الدور'),
            backgroundColor: AppColors.success),
      );
      _loadAdmins();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _removeAdmin(String adminId, String adminName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إزالة المسؤول'),
        content: Text('هل أنت متأكد من إزالة "$adminName" من فريق الإدارة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('إزالة'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestore.collection('users').doc(adminId).update({
        'isAdmin': false,
        'adminRole': FieldValue.delete(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم إزالة المسؤول'),
            backgroundColor: AppColors.success),
      );
      _loadAdmins();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إدارة الأدوار'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Iconsax.refresh), onPressed: _loadAdmins),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAdminDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Iconsax.user_add, color: Colors.white),
        label: const Text('مسؤول جديد', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Roles overview
                  _buildRolesOverview(),
                  const SizedBox(height: 24),

                  // Admins list
                  const Text(
                    'فريق الإدارة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  _buildAdminsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildRolesOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الأدوار المتاحة',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: _roles.map((role) => _buildRoleCard(role)).toList(),
        ),
      ],
    );
  }

  Widget _buildRoleCard(Map<String, dynamic> role) {
    final count = _admins.where((a) => a['adminRole'] == role['id']).length;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (role['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(role['icon'] as IconData,
                      color: role['color'] as Color, size: 20),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role['nameAr'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  role['description'] as String,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminsList() {
    if (_admins.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(Iconsax.people, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('لا يوجد مسؤولين',
                    style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: List.generate(_admins.length, (index) {
          final admin = _admins[index];
          final role = _roles.firstWhere(
            (r) => r['id'] == admin['adminRole'],
            orElse: () => _roles.last,
          );
          final createdAt = admin['createdAt'] != null
              ? DateTime.tryParse(admin['createdAt'])
              : null;

          return Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: (role['color'] as Color).withOpacity(0.1),
                  child: Text(
                    (admin['name'] ?? 'A')[0].toUpperCase(),
                    style: TextStyle(
                        color: role['color'] as Color,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                title: Text(
                  admin['name'] ?? 'مسؤول',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(admin['email'] ?? '',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (role['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            role['nameAr'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: role['color'] as Color,
                            ),
                          ),
                        ),
                        if (createdAt != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            'منذ ${DateFormat('dd/MM/yy').format(createdAt)}',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[500]),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Iconsax.more),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (value == 'remove') {
                      _removeAdmin(admin['id'], admin['name'] ?? 'مسؤول');
                    } else {
                      _updateRole(admin['id'], value);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'moderator',
                      child: ListTile(
                        leading:
                            Icon(Iconsax.shield_tick, color: Color(0xFF3B82F6)),
                        title: Text('مشرف'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'support',
                      child: ListTile(
                        leading: Icon(Iconsax.message_question,
                            color: Color(0xFF10B981)),
                        title: Text('دعم فني'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'accountant',
                      child: ListTile(
                        leading:
                            Icon(Iconsax.calculator, color: Color(0xFF8B5CF6)),
                        title: Text('محاسب'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'remove',
                      child: ListTile(
                        leading: Icon(Iconsax.trash, color: AppColors.error),
                        title: Text('إزالة',
                            style: TextStyle(color: AppColors.error)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < _admins.length - 1) const Divider(height: 1),
            ],
          );
        }),
      ),
    );
  }
}
