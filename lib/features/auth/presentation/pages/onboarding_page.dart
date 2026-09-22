import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../application/auth_controller.dart';
import '../auth_routes.dart';
import '../widgets/auth_scaffold.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  late final PageController _pageController;
  int _currentIndex = 0;

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      imageAsset: 'assets/images/onboarding/onboarding_books.png',
    ),
    _OnboardingItem(
      imageAsset: 'assets/images/onboarding/onboarding_delivery.png',
    ),
    _OnboardingItem(
      imageAsset: 'assets/images/onboarding/onboarding_orders.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeFlow() async {
    await ref.read(authControllerProvider.notifier).completeOnboarding();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(AuthRoutes.home);
  }

  void _goNext() {
    if (_currentIndex == _items.length - 1) {
      _completeFlow();
      return;
    }

    _animateToPage(_currentIndex + 1);
  }

  void _animateToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isTablet = width >= AppBreakpoints.tablet;
    final compact = width < 390;

    return AuthScaffold(
      scrollable: false,
      child: SizedBox(
        height: size.height - MediaQuery.paddingOf(context).vertical - 24,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: compact ? 4 : 8, bottom: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _currentIndex > 0
                        ? () => _animateToPage(_currentIndex - 1)
                        : null,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const Spacer(),
                  TextButton(onPressed: _completeFlow, child: Text(l10n.skip)),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final title = switch (index) {
                    0 => l10n.discoverBooks,
                    1 => l10n.quickDelivery,
                    _ => l10n.trackOrders,
                  };
                  final subtitle = switch (index) {
                    0 => l10n.discoverBooksSubtitle,
                    1 => l10n.quickDeliverySubtitle,
                    _ => l10n.trackOrdersSubtitle,
                  };

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: isTablet ? 20 : 8,
                            bottom: compact ? 14 : 20,
                          ),
                          child: Image.asset(
                            item.imageAsset,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF23252B),
                              fontSize: compact ? 22 : 26,
                            ),
                      ),
                      SizedBox(height: compact ? 8 : 10),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 52 : 12,
                        ),
                        child: Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF7B7B7B),
                                height: 1.45,
                                fontSize: compact ? 14 : 15,
                              ),
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 12),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: compact ? 12 : 20, bottom: 16),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _items.length,
                onDotClicked: _animateToPage,
                effect: ExpandingDotsEffect(
                  expansionFactor: 2.8,
                  spacing: 8,
                  radius: 999,
                  dotWidth: 8,
                  dotHeight: 8,
                  activeDotColor: const Color(0xFF5F92C4),
                  dotColor: const Color(0xFFD0D6E0),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: compact ? 54 : 56,
              child: ElevatedButton(
                onPressed: _goNext,
                child: Text(
                  _currentIndex == _items.length - 1
                      ? l10n.getStarted
                      : l10n.next,
                ),
              ),
            ),
            SizedBox(height: compact ? 8 : 12),
          ],
        ),
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({required this.imageAsset});

  final String imageAsset;
}
