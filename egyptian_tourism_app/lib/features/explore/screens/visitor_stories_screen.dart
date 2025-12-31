import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/colors.dart';

/// شاشة قصص الزوار والمحتوى السياحي
class VisitorStoriesScreen extends StatefulWidget {
  const VisitorStoriesScreen({super.key});

  @override
  State<VisitorStoriesScreen> createState() => _VisitorStoriesScreenState();
}

class _VisitorStoriesScreenState extends State<VisitorStoriesScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  List<Map<String, dynamic>> _stories = [];
  List<Map<String, dynamic>> _tips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    try {
      // Load visitor stories
      final storiesSnapshot = await _firestore
          .collection('visitor_stories')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      // Load travel tips
      final tipsSnapshot = await _firestore
          .collection('travelTips')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      setState(() {
        _stories =
            storiesSnapshot.docs.map((d) => {...d.data(), 'id': d.id}).toList();
        _tips =
            tipsSnapshot.docs.map((d) => {...d.data(), 'id': d.id}).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading content: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.gold,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('اكتشف مصر',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl:
                        'https://images.unsplash.com/photo-1539650116574-8efeb43e2750?w=800',
                    fit: BoxFit.cover,
                    errorWidget: (c, e, s) => Container(color: AppColors.gold),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(
                    text: 'قصص الزوار',
                    icon: Icon(Iconsax.video_play, size: 20)),
                Tab(text: 'نصائح السفر', icon: Icon(Iconsax.lamp_on, size: 20)),
              ],
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildStoriesTab(),
                  _buildTipsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildStoriesTab() {
    if (_stories.isEmpty) {
      return _buildEmptyState('لا توجد قصص حالياً', Iconsax.video_slash);
    }

    return RefreshIndicator(
      onRefresh: _loadContent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _stories.length,
        itemBuilder: (context, index) => _buildStoryCard(_stories[index]),
      ),
    );
  }

  Widget _buildTipsTab() {
    if (_tips.isEmpty) {
      return _buildEmptyState('لا توجد نصائح حالياً', Iconsax.lamp_slash);
    }

    return RefreshIndicator(
      onRefresh: _loadContent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tips.length,
        itemBuilder: (context, index) => _buildTipCard(_tips[index]),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildStoryCard(Map<String, dynamic> story) {
    final createdAt = story['createdAt'] != null
        ? DateTime.parse(story['createdAt'] as String)
        : DateTime.now();

    return GestureDetector(
      onTap: () => _showStoryDetails(story),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15)
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: story['imageUrl'] as String? ?? '',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (c, u) => Container(color: Colors.grey[200]),
                  errorWidget: (c, e, s) => Container(
                    height: 180,
                    color: Colors.grey[200],
                    child:
                        Icon(Iconsax.image, color: Colors.grey[400], size: 40),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.location,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          story['location'] as String? ?? 'مصر',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.gold.withOpacity(0.2),
                        backgroundImage: story['authorImage'] != null
                            ? NetworkImage(story['authorImage'] as String)
                            : null,
                        child: story['authorImage'] == null
                            ? Icon(Iconsax.user,
                                color: AppColors.gold, size: 18)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(story['authorName'] as String? ?? 'زائر',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(
                              DateFormat.yMMMd('ar').format(createdAt),
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Iconsax.share, size: 20),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                            text:
                                '${story['title']}\n\nاقرأ المزيد في تطبيق بازار',
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('تم نسخ الرابط'),
                              backgroundColor: AppColors.gold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    story['title'] as String? ?? '',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    story['excerpt'] as String? ?? '',
                    style: TextStyle(color: Colors.grey[600], height: 1.5),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatChip(
                          Iconsax.heart, story['likes']?.toString() ?? '0'),
                      const SizedBox(width: 12),
                      _buildStatChip(Iconsax.message,
                          story['comments']?.toString() ?? '0'),
                      const Spacer(),
                      Text('اقرأ المزيد',
                          style: TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios,
                          size: 14, color: AppColors.gold),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(Map<String, dynamic> tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getTipIcon(tip['category'] as String?),
                color: AppColors.gold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip['title'] as String? ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  tip['content'] as String? ?? '',
                  style: TextStyle(color: Colors.grey[600], height: 1.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tip['category'] as String? ?? 'عام',
                    style: TextStyle(
                        color: AppColors.secondaryTeal,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      ],
    );
  }

  IconData _getTipIcon(String? category) {
    switch (category) {
      case 'transportation':
        return Iconsax.car;
      case 'food':
        return Iconsax.coffee;
      case 'safety':
        return Iconsax.shield_tick;
      case 'culture':
        return Iconsax.book;
      case 'money':
        return Iconsax.money;
      default:
        return Iconsax.lamp_on;
    }
  }

  void _showStoryDetails(Map<String, dynamic> story) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Image
                CachedNetworkImage(
                  imageUrl: story['imageUrl'] as String? ?? '',
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (c, e, s) =>
                      Container(height: 250, color: Colors.grey[200]),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story['title'] as String? ?? '',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.gold.withOpacity(0.2),
                            child: Icon(Iconsax.user, color: AppColors.gold),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(story['authorName'] as String? ?? 'زائر',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Text(story['location'] as String? ?? 'مصر',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        story['content'] as String? ??
                            story['excerpt'] as String? ??
                            '',
                        style: const TextStyle(height: 1.8, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
