/// ⚡ شريط الأفعال السريعة — أزرار اقتراحات أسفل رد الـ AI
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:egyptian_tourism_app/core/constants/colors.dart';
import 'package:egyptian_tourism_app/models/ai_chat_models.dart';

class QuickActionsBar extends StatelessWidget {
  final List<AiQuickAction> actions;
  final void Function(String message) onActionTapped;

  const QuickActionsBar({
    super.key,
    required this.actions,
    required this.onActionTapped,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Padding(
        padding: const EdgeInsets.only(left: 52, right: 12, top: 4, bottom: 8),
        child: SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: actions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final action = actions[index];
              return _QuickActionChip(
                action: action,
                onTap: () => onActionTapped(action.message),
                delay: index * 80,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _QuickActionChip extends StatefulWidget {
  final AiQuickAction action;
  final VoidCallback onTap;
  final int delay;

  const _QuickActionChip({
    required this.action,
    required this.onTap,
    required this.delay,
  });

  @override
  State<_QuickActionChip> createState() => _QuickActionChipState();
}

class _QuickActionChipState extends State<_QuickActionChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // تشغيل الأنيميشن بتأخير
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondaryTeal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.secondaryTeal.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                widget.action.label,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTeal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
