import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/top_toast.dart';

/// Result returned when the user posts a review.
class ReviewResult {
  const ReviewResult({required this.rating, required this.comment});

  final int rating;
  final String comment;
}

class ReviewBottomSheet extends StatefulWidget {
  const ReviewBottomSheet({super.key, this.reviewerName});

  final String? reviewerName;

  @override
  State<ReviewBottomSheet> createState() => _ReviewBottomSheetState();

  /// Shows the review sheet and resolves with the [ReviewResult] once posted,
  /// or `null` if the user cancels / dismisses it.
  static Future<ReviewResult?> show(
    BuildContext context, {
    String? reviewerName,
  }) {
    return showModalBottomSheet<ReviewResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReviewBottomSheet(reviewerName: reviewerName),
    );
  }
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet> {
  static const Color _accentBlue = Color(0xFF2E9BE5);
  static const Color _titleColor = Color(0xFF243041);
  static const LinearGradient _buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6BA3D6), Color(0xFF5680AB)],
  );

  final TextEditingController _controller = TextEditingController();
  int _rating = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _post() {
    final l10n = AppLocalizations.of(context);
    if (_rating == 0) {
      showTopToast(context, title: l10n.selectRating, type: ToastType.error);
      return;
    }
    Navigator.of(context).pop(
      ReviewResult(rating: _rating, comment: _controller.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E6EC),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFF3F8FC),
                backgroundImage: const AssetImage(
                  'assets/images/profile_placeholder.png',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.reviewerName ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _titleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Interactive star rating
          Row(
            children: List.generate(5, (index) {
              final filled = index < _rating;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _rating = index + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFFFC107),
                    size: 34,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l10n.writeShortReview,
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8E98A5)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD7DCE3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD7DCE3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _accentBlue),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: _accentBlue, width: 1.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.cancel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _accentBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GradientButton(
                  gradient: _buttonGradient,
                  onPressed: _post,
                  label: l10n.post,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A pill button filled with a brand gradient (matches the Figma "Post" button).
class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.gradient,
    required this.onPressed,
    required this.label,
  });

  final Gradient gradient;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
