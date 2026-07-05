import 'dart:async';

import 'package:flutter/material.dart';

/// Visual intent of a [showTopToast] message.
enum ToastType { success, error, info }

class _ToastStyle {
  const _ToastStyle(this.accent, this.icon);
  final Color accent;
  final IconData icon;
}

const _styles = <ToastType, _ToastStyle>{
  ToastType.success: _ToastStyle(Color(0xFF2E9E6B), Icons.check_circle_rounded),
  ToastType.error: _ToastStyle(Color(0xFFC74848), Icons.error_outline_rounded),
  ToastType.info: _ToastStyle(Color(0xFF5A91C4), Icons.info_outline_rounded),
};

/// Shows a branded toast that slides down from the top of the screen.
///
/// Styled to match the app's card language (rounded surface, subtle border +
/// shadow) with a colored accent badge that reflects the [type]. Auto-dismisses
/// and can be tapped or swiped up to dismiss early.
/// Displays the toast. Provide either a live [context] or a pre-captured
/// [overlay] (useful after an `await`, where using a [BuildContext] is unsafe).
void showTopToast(
  BuildContext? context, {
  required String title,
  String? subtitle,
  ToastType type = ToastType.success,
  IconData? icon,
  Duration duration = const Duration(milliseconds: 2600),
  OverlayState? overlay,
}) {
  final style = _styles[type]!;
  overlay ??= Overlay.of(context!, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _TopToast(
      title: title,
      subtitle: subtitle,
      accent: style.accent,
      icon: icon ?? style.icon,
      duration: duration,
      onDismissed: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _TopToast extends StatefulWidget {
  const _TopToast({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.duration,
    required this.onDismissed,
  });

  final String title;
  final String? subtitle;
  final Color accent;
  final IconData icon;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    reverseDuration: const Duration(milliseconds: 260),
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -1.4),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.6, curve: Curves.easeOut),
  );

  Timer? _timer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    _timer?.cancel();
    if (mounted) await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF23252B) : Colors.white;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: Material(
                color: Colors.transparent,
                child: Dismissible(
                  key: const ValueKey('top_toast'),
                  direction: DismissDirection.up,
                  onDismissed: (_) {
                    _timer?.cancel();
                    _dismissing = true;
                    widget.onDismissed();
                  },
                  child: GestureDetector(
                    onTap: _dismiss,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF33363D)
                              : const Color(0xFFE9EDF2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: widget.accent.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.icon,
                              color: widget.accent,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.title,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF23252B),
                                  ),
                                ),
                                if (widget.subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.subtitle!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFFAFB7C1),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
