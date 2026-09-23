import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    this.topSpacing = 48,
    this.bottomSpacing = 36,
    this.logoWidth = 240,
  });

  final double topSpacing;
  final double bottomSpacing;
  final double logoWidth;

  static const logoAsset = 'assets/images/app_logo.png';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 390;

    return Padding(
      padding: EdgeInsets.only(
        top: compact ? topSpacing * 0.62 : topSpacing,
        bottom: compact ? bottomSpacing * 0.72 : bottomSpacing,
      ),
      child: Center(
        child: Image.asset(
          logoAsset,
          width: compact ? logoWidth * 0.78 : logoWidth,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class AuthTitleBlock extends StatelessWidget {
  const AuthTitleBlock({
    super.key,
    required this.title,
    this.subtitle,
    this.bottomSpacing = 28,
    this.centered = true,
  });

  final String title;
  final String? subtitle;
  final double bottomSpacing;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 390;
    final crossAxisAlignment = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final textAlign = centered ? TextAlign.center : TextAlign.start;

    return Padding(
      padding: EdgeInsets.only(
        bottom: compact ? bottomSpacing - 8 : bottomSpacing,
      ),
      child: Align(
        alignment: centered ? Alignment.center : Alignment.centerLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: crossAxisAlignment,
          children: [
            Text(
              title,
              textAlign: textAlign,
              style:
                  (compact
                          ? theme.textTheme.headlineSmall
                          : theme.textTheme.headlineMedium)
                      ?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF23252B),
                      ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: textAlign,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF818181),
                  fontWeight: FontWeight.w400,
                  fontSize: compact ? 14 : 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 390;

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 8 : 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111111),
        ),
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 390;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: const Color(0xFF303030),
        fontWeight: FontWeight.w500,
        fontSize: compact ? 15 : 16,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isBusy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 390;

    return SizedBox(
      width: double.infinity,
      height: compact ? 56 : 60,
      child: ElevatedButton(
        onPressed: isBusy ? null : onPressed,
        child: isBusy
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 16 : 17,
                ),
              ),
      ),
    );
  }
}

class SocialActionButton extends StatelessWidget {
  const SocialActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconColor,
    this.isBusy = false,
    this.backgroundColor,
    this.textColor = const Color(0xFF23252B),
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final bool isBusy;
  final Color? backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 390;

    return SizedBox(
      width: double.infinity,
      height: compact ? 58 : 62,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
        ),
        icon: isBusy
            ? SizedBox(
                width: compact ? 22 : 24,
                height: compact ? 22 : 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor,
                ),
              )
            : Icon(icon, color: iconColor, size: compact ? 24 : 28),
        label: Text(
          label,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: textColor,
            fontSize: compact ? 15 : 16,
          ),
        ),
      ),
    );
  }
}

class InlineAuthLink extends StatelessWidget {
  const InlineAuthLink({
    super.key,
    required this.leadingText,
    required this.actionText,
    required this.onTap,
  });

  final String leadingText;
  final String actionText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 390;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          leadingText,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: const Color(0xFF23252B),
            fontSize: compact ? 15 : 16,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionText,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: onTap == null
                  ? const Color(0xFF9CA6B3)
                  : const Color(0xFF005FC5),
              fontSize: compact ? 15 : 16,
            ),
          ),
        ),
      ],
    );
  }
}

class AuthSurface extends StatelessWidget {
  const AuthSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.large,
        color: Colors.white.withValues(alpha: 0.52),
      ),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }
}
