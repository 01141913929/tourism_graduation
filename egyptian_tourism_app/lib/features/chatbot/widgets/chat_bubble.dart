// 💬 فقاعة الرسالة — تعرض رسائل المستخدم والـ AI
// مع دعم Markdown rendering احترافي
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:egyptian_tourism_app/core/constants/colors.dart';
import 'package:egyptian_tourism_app/models/ai_chat_models.dart';

class ChatBubble extends StatelessWidget {
  final AiChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // أيقونة الروبوت (للـ AI فقط)
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.secondaryTeal,
                    AppColors.secondaryTealLight,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // الفقاعة
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primaryOrange, AppColors.gold],
                      )
                    : null,
                color: isUser ? null : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isUser ? AppColors.primaryOrange : Colors.black)
                        .withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: isUser
                    ? null
                    : Border.all(color: Colors.white, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // شارة الوكيل (للـ AI فقط)
                  if (!isUser && message.agentUsed.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        message.agentDisplayName,
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryTeal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],

                  // === نص الرسالة ===
                  if (isUser)
                    // رسائل المستخدم — نص عادي
                    Text(
                      message.text,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    )
                  else
                    // رسائل AI — Markdown rendering
                    MarkdownBody(
                      data: message.text,
                      selectable: true,
                      shrinkWrap: true,
                      softLineBreak: true,
                      styleSheet: _buildMarkdownStyle(context),
                      onTapLink: (text, href, title) {
                        if (href != null) {
                          launchUrl(Uri.parse(href),
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      imageBuilder: (uri, title, alt) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: uri.toString(),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (_, __) => Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppColors.divider,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.secondaryTeal,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.divider,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Icon(Icons.broken_image_outlined,
                                    color: AppColors.textHint, size: 32),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 4),

                  // الوقت + مؤشر البث
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('hh:mm a', 'ar').format(message.timestamp),
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          color: isUser
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppColors.textHint,
                        ),
                      ),
                      if (message.isStreaming) ...[
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isUser
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : AppColors.secondaryTeal,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // المصادر (لو فيه)
                  if (!isUser && message.sources.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    const Divider(height: 1),
                    const SizedBox(height: 4),
                    Text(
                      '📚 المصادر: ${message.sources.join(' • ')}',
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: AppColors.textHint,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // مساحة للرسائل اليمينية
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  /// بناء ستايل Markdown بألوان التطبيق المصري
  MarkdownStyleSheet _buildMarkdownStyle(BuildContext context) {
    final baseText = GoogleFonts.cairo(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
      height: 1.6,
    );

    return MarkdownStyleSheet(
      // نص عادي
      p: baseText,

      // عناوين
      h1: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.secondaryTealDark,
        height: 1.4,
      ),
      h2: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.secondaryTeal,
        height: 1.4,
      ),
      h3: GoogleFonts.cairo(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryOrange,
        height: 1.4,
      ),

      // Bold + Italic
      strong: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      em: GoogleFonts.cairo(
        fontSize: 14,
        fontStyle: FontStyle.italic,
        color: AppColors.textSecondary,
      ),

      // قوائم
      listBullet: baseText.copyWith(color: AppColors.secondaryTeal),
      listIndent: 16,

      // روابط
      a: GoogleFonts.cairo(
        fontSize: 14,
        color: AppColors.secondaryTeal,
        decoration: TextDecoration.underline,
        decorationColor: AppColors.secondaryTeal,
      ),

      // بلوكات كود
      code: GoogleFonts.cairo(
        fontSize: 12,
        color: AppColors.pharaohBlue,
        backgroundColor: AppColors.sandBeige.withValues(alpha: 0.3),
      ),
      codeblockDecoration: BoxDecoration(
        color: AppColors.sandBeige.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      codeblockPadding: const EdgeInsets.all(12),

      // اقتباسات
      blockquoteDecoration: BoxDecoration(
        border: const Border(
          right: BorderSide(
            color: AppColors.gold,
            width: 3,
          ),
        ),
        color: AppColors.gold.withValues(alpha: 0.05),
      ),
      blockquotePadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

      // فواصل
      horizontalRuleDecoration: BoxDecoration(
        border: const Border(
          top: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
      ),

      // جداول
      tableHead: GoogleFonts.cairo(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      tableBody: GoogleFonts.cairo(
        fontSize: 13,
        color: AppColors.textSecondary,
      ),
      tableBorder: TableBorder.all(
        color: AppColors.divider,
        width: 0.5,
        borderRadius: BorderRadius.circular(6),
      ),
      tableCellsPadding: const EdgeInsets.all(8),
    );
  }
}
