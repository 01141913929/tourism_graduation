import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/constants/colors.dart';
import '../../../models/models.dart';
import '../../../repositories/artifact_repository.dart';

class ArtifactDetailsScreen extends StatefulWidget {
  final Artifact artifact;

  const ArtifactDetailsScreen({super.key, required this.artifact});

  @override
  State<ArtifactDetailsScreen> createState() => _ArtifactDetailsScreenState();
}

class _ArtifactDetailsScreenState extends State<ArtifactDetailsScreen> {
  bool _isFavorite = false;
  int _selectedImageIndex = 0;
  final ArtifactRepository _artifactRepository = ArtifactRepository();
  List<Artifact> _relatedArtifacts = [];

  late List<String> _images;

  @override
  void initState() {
    super.initState();
    _images = [
      widget.artifact.imageUrl,
      widget.artifact.imageUrl,
      widget.artifact.imageUrl,
    ];
    _loadRelatedArtifacts();
  }

  Future<void> _loadRelatedArtifacts() async {
    try {
      final artifacts = await _artifactRepository.getArtifacts();
      if (mounted) {
        setState(() {
          _relatedArtifacts = artifacts
              .where((a) => a.id != widget.artifact.id)
              .take(4)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading related artifacts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: _buildContent(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: AppColors.white,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_forward_ios,
            color: AppColors.textPrimary,
            size: 18,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            setState(() {
              _isFavorite = !_isFavorite;
            });
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              _isFavorite ? Iconsax.heart5 : Iconsax.heart,
              color: _isFavorite ? AppColors.error : AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Iconsax.share,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Image
            PageView.builder(
              onPageChanged: (index) {
                setState(() {
                  _selectedImageIndex = index;
                });
              },
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return Hero(
                  tag: 'artifact_${widget.artifact.id}',
                  child: CachedNetworkImage(
                    imageUrl: _images[index],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
            // Gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.white.withValues(alpha: 0.9),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Image indicators
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_images.length, (index) {
                  return Container(
                    width: _selectedImageIndex == index ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _selectedImageIndex == index
                          ? AppColors.primaryOrange
                          : AppColors.textHint,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            // Era badge
            Positioned(
              top: 100,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondaryTeal,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryTeal.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  widget.artifact.era,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Title
            Text(
              widget.artifact.nameAr,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 12),

            // Location & Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Rating
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '4.9',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: AppColors.gold,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Location
                Row(
                  children: [
                    Text(
                      widget.artifact.location,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Iconsax.location,
                      size: 16,
                      color: AppColors.primaryOrange,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Description Section
            const Text(
              'عن التحفة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.artifact.descriptionAr,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.8,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 24),

            // Details Grid
            _buildDetailsGrid(),
            const SizedBox(height: 24),

            // Audio Tour
            _buildAudioTour(),
            const SizedBox(height: 24),

            // Related Artifacts
            _buildRelatedArtifacts(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsGrid() {
    final details = [
      {
        'icon': Iconsax.calendar,
        'label': 'الفترة',
        'value': widget.artifact.era
      },
      {
        'icon': Iconsax.location,
        'label': 'الموقع',
        'value': widget.artifact.location
      },
      {'icon': Iconsax.ruler, 'label': 'الأبعاد', 'value': '45 × 30 سم'},
      {'icon': Iconsax.box_1, 'label': 'الخامة', 'value': 'ذهب وأحجار كريمة'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildDetailItem(details[0])),
              const SizedBox(width: 12),
              Expanded(child: _buildDetailItem(details[1])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDetailItem(details[2])),
              const SizedBox(width: 12),
              Expanded(child: _buildDetailItem(details[3])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(Map<String, dynamic> detail) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                detail['label'],
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                detail['icon'] as IconData,
                size: 16,
                color: AppColors.primaryOrange,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            detail['value'],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildAudioTour() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryTeal,
            AppColors.secondaryTeal.withValues(alpha: 0.8),
          ],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryTeal.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Iconsax.play,
              color: AppColors.secondaryTeal,
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'جولة صوتية',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '5:32 دقيقة',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          const Icon(
            Iconsax.headphone,
            color: AppColors.white,
            size: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedArtifacts() {
    final related = _relatedArtifacts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'تحف مشابهة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true,
            itemCount: related.length,
            itemBuilder: (context, index) {
              final artifact = related[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArtifactDetailsScreen(artifact: artifact),
                    ),
                  );
                },
                child: Container(
                  width: 130,
                  margin: EdgeInsets.only(
                      left: index == related.length - 1 ? 0 : 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: artifact.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                artifact.nameAr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                artifact.era,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: const BorderSide(color: AppColors.primaryOrange),
                ),
                icon: const Icon(Iconsax.map, color: AppColors.primaryOrange),
                label: const Text(
                  'الخريطة',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Iconsax.location, color: AppColors.white),
                label: const Text(
                  'الذهاب للتحفة',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
