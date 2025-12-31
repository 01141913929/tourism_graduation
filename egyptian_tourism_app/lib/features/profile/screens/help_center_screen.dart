import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/constants/colors.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _expandedIndex = -1;

  final List<Map<String, dynamic>> _faqCategories = [
    {
      'icon': Iconsax.box,
      'title': 'الطلبات والشحن',
      'questions': [
        {
          'q': 'كيف يمكنني تتبع طلبي؟',
          'a':
              'يمكنك تتبع طلبك من خلال صفحة "طلباتي" في حسابك الشخصي، أو عبر رابط التتبع المرسل إلى بريدك الإلكتروني.',
        },
        {
          'q': 'ما هي مدة التوصيل؟',
          'a':
              'تتراوح مدة التوصيل من 2-5 أيام عمل داخل مصر، و7-14 يوم للشحن الدولي.',
        },
        {
          'q': 'هل يمكنني تغيير عنوان التوصيل؟',
          'a':
              'نعم، يمكنك تغيير عنوان التوصيل قبل شحن الطلب من صفحة تتبع الطلب.',
        },
      ],
    },
    {
      'icon': Iconsax.money_recive,
      'title': 'الدفع والاسترداد',
      'questions': [
        {
          'q': 'ما هي طرق الدفع المتاحة؟',
          'a':
              'نقبل البطاقات الائتمانية (Visa, MasterCard)، Apple Pay، والدفع عند الاستلام.',
        },
        {
          'q': 'كيف يمكنني استرداد أموالي؟',
          'a':
              'بعد الموافقة على طلب الإرجاع، يتم إعادة المبلغ خلال 5-10 أيام عمل إلى نفس طريقة الدفع.',
        },
      ],
    },
    {
      'icon': Iconsax.refresh,
      'title': 'الإرجاع والاستبدال',
      'questions': [
        {
          'q': 'ما هي سياسة الإرجاع؟',
          'a':
              'يمكنك إرجاع المنتج خلال 14 يوم من تاريخ الاستلام بشرط أن يكون في حالته الأصلية.',
        },
        {
          'q': 'هل الإرجاع مجاني؟',
          'a': 'نعم، الإرجاع مجاني لجميع المنتجات داخل مصر.',
        },
      ],
    },
    {
      'icon': Iconsax.user,
      'title': 'الحساب والخصوصية',
      'questions': [
        {
          'q': 'كيف يمكنني تغيير كلمة المرور؟',
          'a': 'اذهب إلى الإعدادات > الأمان > تغيير كلمة المرور.',
        },
        {
          'q': 'كيف أحذف حسابي؟',
          'a': 'تواصل معنا عبر البريد الإلكتروني أو الدردشة لطلب حذف الحساب.',
        },
      ],
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          _buildAppBar(),

          // Quick Actions
          SliverToBoxAdapter(
            child: _buildQuickActions(),
          ),

          // FAQ Section
          SliverToBoxAdapter(
            child: _buildFAQSection(),
          ),

          // Contact Section
          SliverToBoxAdapter(
            child: _buildContactSection(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.secondaryTeal,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_forward_ios,
            color: AppColors.white,
            size: 18,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.secondaryTeal, Color(0xFF14665A)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: Stack(
            children: [
              // Decorative elements
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Icon(
                        Iconsax.message_question,
                        color: AppColors.white,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'مركز المساعدة',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'كيف يمكننا مساعدتك اليوم؟',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Search bar
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            hintText: 'ابحث عن سؤال...',
                            hintStyle: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 14,
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryTeal,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.search,
                                color: AppColors.white,
                                size: 20,
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Iconsax.message,
        'label': 'الدردشة',
        'color': AppColors.primaryOrange
      },
      {'icon': Iconsax.call, 'label': 'اتصل بنا', 'color': AppColors.success},
      {'icon': Iconsax.sms, 'label': 'البريد', 'color': AppColors.pharaohBlue},
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: actions.map((action) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: (action['color'] as Color).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      action['icon'] as IconData,
                      color: action['color'] as Color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    action['label'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'الأسئلة الشائعة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...(_faqCategories.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            return _buildFAQCategory(category, index);
          })),
        ],
      ),
    );
  }

  Widget _buildFAQCategory(Map<String, dynamic> category, int categoryIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textSecondary,
          ),
          trailing: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              category['icon'] as IconData,
              color: AppColors.primaryOrange,
              size: 22,
            ),
          ),
          title: Text(
            category['title'],
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
          children: [
            const Divider(),
            ...(category['questions'] as List<Map<String, String>>).map((qa) {
              return _buildQuestionItem(qa);
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionItem(Map<String, String> qa) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: const Icon(
            Icons.keyboard_arrow_down,
            size: 20,
          ),
          trailing: const Icon(
            Iconsax.message_question,
            size: 18,
            color: AppColors.secondaryTeal,
          ),
          title: Text(
            qa['q']!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
          children: [
            Text(
              qa['a']!,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryOrange,
              AppColors.primaryOrange.withValues(alpha: 0.8),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryOrange.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'ابدأ المحادثة',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'لازلت تحتاج المساعدة؟',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'فريقنا متاح على مدار الساعة',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
