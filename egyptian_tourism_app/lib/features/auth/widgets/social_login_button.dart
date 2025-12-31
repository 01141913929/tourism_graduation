import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

/// Reusable social login button with brand styling
class SocialLoginButton extends StatelessWidget {
  final String icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final Color iconColor;
  final bool isApple;
  final VoidCallback onPressed;

  const SocialLoginButton({
    super.key,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    required this.iconColor,
    this.isApple = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: borderColor != null
                ? BorderSide(color: borderColor!)
                : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            if (isApple)
              Icon(
                Icons.apple,
                color: iconColor,
                size: 26,
              )
            else
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: icon == 'G' ? backgroundColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: TextStyle(
                      fontSize: icon == 'G' ? 20 : 22,
                      fontWeight: FontWeight.w800,
                      color: iconColor,
                      fontFamily: icon == 'f' ? 'Arial' : null,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            // Label
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            // Placeholder for balance
            const SizedBox(width: 28),
          ],
        ),
      ),
    );
  }
}

/// Circular social icon button for compact layout
class SocialIconButton extends StatelessWidget {
  final IconData? icon;
  final String? text;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const SocialIconButton({
    super.key,
    this.icon,
    this.text,
    required this.color,
    this.backgroundColor = AppColors.white,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: text != null
              ? Text(
                  text!,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                )
              : Icon(icon, color: color, size: 28),
        ),
      ),
    );
  }
}
