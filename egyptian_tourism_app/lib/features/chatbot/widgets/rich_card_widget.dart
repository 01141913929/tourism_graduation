/// 🎴 ويدجت الكروت الغنية — عرض منتجات وآثار وبازارات
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:egyptian_tourism_app/core/constants/colors.dart';
import 'package:egyptian_tourism_app/models/ai_chat_models.dart';

class RichCardWidget extends StatelessWidget {
  final AiRichCard card;
  final void Function(AiCardAction action)? onAction;

  const RichCardWidget({
    super.key,
    required this.card,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 52, right: 12, top: 4, bottom: 8),
      child: _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    switch (card.type) {
      case 'product':
        return _ProductCard(card: card, onAction: onAction);
      case 'artifact':
        return _ArtifactCard(card: card, onAction: onAction);
      case 'bazaar':
        return _BazaarCard(card: card, onAction: onAction);
      case 'cart_summary':
        return _CartSummaryCard(card: card, onAction: onAction);
      default:
        return _GenericCard(card: card, onAction: onAction);
    }
  }
}

/// ========================================
/// 🛍️ كارت منتج
/// ========================================
class _ProductCard extends StatelessWidget {
  final AiRichCard card;
  final void Function(AiCardAction action)? onAction;

  const _ProductCard({required this.card, this.onAction});

  @override
  Widget build(BuildContext context) {
    final data = card.data;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة المنتج
          if (data['imageUrl'] != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: data['imageUrl'] as String,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 140,
                  color: AppColors.sandBeige,
                  child: const Center(
                    child: Icon(Icons.shopping_bag_outlined,
                        color: AppColors.gold, size: 40),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 140,
                  color: AppColors.sandBeige,
                  child: const Center(
                    child: Icon(Icons.image_not_supported_outlined,
                        color: AppColors.textHint, size: 40),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الاسم والتقييم
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data['nameAr'] as String? ??
                            data['name'] as String? ??
                            '',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (data['rating'] != null) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: AppColors.gold, size: 14),
                      Text(
                        ' ${data['rating']}',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),

                // السعر
                Row(
                  children: [
                    Text(
                      '${data['price'] ?? ''} جنيه',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                    if (data['oldPrice'] != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${data['oldPrice']} جنيه',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.textHint,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),

                // البازار
                if (data['bazaarName'] != null)
                  Text(
                    '🏪 ${data['bazaarName']}',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),

                // أزرار الأفعال
                if (card.actions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _ActionButtons(actions: card.actions, onAction: onAction),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ========================================
/// 🏺 كارت أثر
/// ========================================
class _ArtifactCard extends StatelessWidget {
  final AiRichCard card;
  final void Function(AiCardAction action)? onAction;

  const _ArtifactCard({required this.card, this.onAction});

  @override
  Widget build(BuildContext context) {
    final data = card.data;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.pharaohBlue.withValues(alpha: 0.05),
            AppColors.gold.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance,
                    color: AppColors.gold, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['nameAr'] as String? ??
                          data['name'] as String? ??
                          '',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pharaohBlue,
                      ),
                    ),
                    if (data['era'] != null)
                      Text(
                        '📅 ${data['era']}',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (data['descriptionAr'] != null || data['description'] != null) ...[
            const SizedBox(height: 8),
            Text(
              data['descriptionAr'] as String? ??
                  data['description'] as String? ??
                  '',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (card.actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ActionButtons(actions: card.actions, onAction: onAction),
          ],
        ],
      ),
    );
  }
}

/// ========================================
/// 🏪 كارت بازار
/// ========================================
class _BazaarCard extends StatelessWidget {
  final AiRichCard card;
  final void Function(AiCardAction action)? onAction;

  const _BazaarCard({required this.card, this.onAction});

  @override
  Widget build(BuildContext context) {
    final data = card.data;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.secondaryTeal.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondaryTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.store,
                    color: AppColors.secondaryTeal, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['nameAr'] as String? ??
                          data['name'] as String? ??
                          '',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (data['address'] != null)
                      Text(
                        '📍 ${data['address']}',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // حالة الفتح
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: data['isOpen'] == true
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data['isOpen'] == true ? 'مفتوح ✅' : 'مغلق ❌',
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: data['isOpen'] == true
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          if (data['workingHours'] != null) ...[
            const SizedBox(height: 6),
            Text(
              '🕐 ${data['workingHours']}',
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (card.actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ActionButtons(actions: card.actions, onAction: onAction),
          ],
        ],
      ),
    );
  }
}

/// ========================================
/// 🛒 كارت ملخص السلة
/// ========================================
class _CartSummaryCard extends StatelessWidget {
  final AiRichCard card;
  final void Function(AiCardAction action)? onAction;

  const _CartSummaryCard({required this.card, this.onAction});

  @override
  Widget build(BuildContext context) {
    final data = card.data;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_cart,
                  color: AppColors.primaryOrange, size: 22),
              const SizedBox(width: 8),
              Text(
                'سلة المشتريات',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryOrange,
                ),
              ),
              const Spacer(),
              Text(
                '${data['total'] ?? 0} جنيه',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryOrange,
                ),
              ),
            ],
          ),
          if (data['itemCount'] != null) ...[
            const SizedBox(height: 4),
            Text(
              '${data['itemCount']} منتجات',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (card.actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ActionButtons(actions: card.actions, onAction: onAction),
          ],
        ],
      ),
    );
  }
}

/// ========================================
/// كارت عام (fallback)
/// ========================================
class _GenericCard extends StatelessWidget {
  final AiRichCard card;
  final void Function(AiCardAction action)? onAction;

  const _GenericCard({required this.card, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.data['title'] as String? ?? card.type,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (card.data['description'] != null) ...[
            const SizedBox(height: 4),
            Text(
              card.data['description'] as String,
              style: GoogleFonts.cairo(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          if (card.actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ActionButtons(actions: card.actions, onAction: onAction),
          ],
        ],
      ),
    );
  }
}

/// ========================================
/// أزرار الأفعال المشتركة
/// ========================================
class _ActionButtons extends StatelessWidget {
  final List<AiCardAction> actions;
  final void Function(AiCardAction action)? onAction;

  const _ActionButtons({required this.actions, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: actions.map((action) {
        return SizedBox(
          height: 32,
          child: ElevatedButton.icon(
            onPressed: () => onAction?.call(action),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getActionColor(action.action),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
              textStyle: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: Icon(_getActionIcon(action.action), size: 14),
            label: Text(action.label),
          ),
        );
      }).toList(),
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'add_to_cart':
        return AppColors.primaryOrange;
      case 'navigate':
        return AppColors.secondaryTeal;
      case 'web_link':
        return AppColors.pharaohBlue;
      default:
        return AppColors.secondaryTeal;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'add_to_cart':
        return Icons.add_shopping_cart;
      case 'navigate':
        return Icons.arrow_forward_ios;
      case 'web_link':
        return Icons.open_in_new;
      case 'send_message':
        return Icons.message;
      default:
        return Icons.touch_app;
    }
  }
}
