import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card, PaymentMethod;

import '../../../../core/config/app_config.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/services/address_suggestion_service.dart';
import '../../../../core/utils/country_codes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/top_toast.dart';
import '../../../home/application/store_controller.dart';
import '../../../home/domain/store_models.dart';
import '../../../order/application/order_controller.dart';
import '../../../order/data/order_repository.dart';
import '../../../order/data/payment_repository.dart';
import '../../../order/domain/order_models.dart';
import '../../application/settings_provider.dart';
import '../widgets/country_code_picker.dart';
import '../widgets/order_confirmed_sheet.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressFocus = FocusNode();
  final _line2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postalController = TextEditingController();
  final _stateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressService = AddressSuggestionService();

  CountryCode _country = kDefaultCountryCode;
  bool _isSubmitting = false;

  /// True on iOS/macOS → offer Apple Pay; otherwise → offer Google Pay.
  bool get _isApplePlatform =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();
    _debugCheckGooglePaySupport();
    _loadSavedAddress();
  }

  /// Pre-fills the form with the recipient + delivery address from the user's
  /// most recent order, so returning customers don't retype everything.
  /// Best-effort: silently does nothing on first-ever order or on error.
  Future<void> _loadSavedAddress() async {
    final saved = await ref.read(orderRepositoryProvider).getLastAddress();
    if (saved == null || !mounted) return;

    setState(() {
      if (_nameController.text.isEmpty) _nameController.text = saved.name;
      if (_addressController.text.isEmpty) {
        _addressController.text = saved.line1;
      }
      if (_line2Controller.text.isEmpty) _line2Controller.text = saved.line2;
      if (_cityController.text.isEmpty) _cityController.text = saved.city;
      if (_postalController.text.isEmpty) {
        _postalController.text = saved.postalCode;
      }
      if (_stateController.text.isEmpty) _stateController.text = saved.state;

      // Restore the phone number and dial-code country, if saved.
      final match = _matchSavedPhone(saved);
      if (match != null && _phoneController.text.isEmpty) {
        _country = match.country;
        _phoneController.text = match.nationalNumber;
      }
    });
  }

  /// Splits a saved "+33 612345678" phone into its country + national number.
  ({CountryCode country, String nationalNumber})? _matchSavedPhone(
    SavedAddress saved,
  ) {
    final raw = saved.phone.trim();
    if (raw.isEmpty) return null;
    // Prefer the saved country ISO to resolve the dial code unambiguously.
    CountryCode? byIso;
    for (final c in kCountryCodes) {
      if (c.iso == saved.country) {
        byIso = c;
        break;
      }
    }
    for (final country in [?byIso, ...kCountryCodes]) {
      if (raw.startsWith(country.dialCode)) {
        final national = raw
            .substring(country.dialCode.length)
            .replaceAll(RegExp(r'\D'), '');
        if (national.isNotEmpty) {
          return (country: country, nationalNumber: national);
        }
      }
    }
    return null;
  }

  /// Debug aid: the PaymentSheet only shows the Google Pay button when the
  /// device passes Google's isReadyToPay check (Play services + a signed-in
  /// Google account). This logs the verdict so a missing button is
  /// explainable from the console.
  Future<void> _debugCheckGooglePaySupport() async {
    if (!kDebugMode ||
        kIsWeb ||
        _isApplePlatform ||
        kStripePublishableKey.isEmpty) {
      return;
    }
    try {
      final supported = await Stripe.instance.isPlatformPaySupported(
        googlePay: const IsGooglePaySupportedParams(testEnv: true),
      );
      debugPrint(
        '[stripe] Google Pay ready on this device: $supported '
        '(needs Google Play services + signed-in Google account)',
      );
    } catch (e) {
      debugPrint('[stripe] Google Pay support check failed: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _addressFocus.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _postalController.dispose();
    _stateController.dispose();
    _phoneController.dispose();
    _addressService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final storeState = ref.watch(storeControllerProvider);
    final catalog = ref.watch(storeCatalogProvider);

    final cartItems = storeState.cartQuantities.entries
        .where((e) => catalog.any((b) => b.id == e.key))
        .map((e) => catalog.firstWhere((b) => b.id == e.key))
        .toList();

    final storeController = ref.read(storeControllerProvider.notifier);
    final subtotal = storeController.subtotal(cartItems);
    // Delivery fee is the global admin-configured charge from the backend
    // (GET /admin-settings), applied once per order and added to the total
    // that gets charged. Falls back to the backend default while loading.
    final deliveryFee = cartItems.isEmpty
        ? 0.0
        : ref.watch(deliveryFeeProvider);
    final total = subtotal + deliveryFee;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.chevron_left,
            color: Color(0xFF243041),
            size: 28,
          ),
        ),
        title: Text(
          l10n.paymentDetails,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF243041),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EBF0)),
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.checkout,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF243041),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.completeOrderDetails,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8E98A5),
                  ),
                ),
                const SizedBox(height: 24),

                _buildInputLabel(Icons.person_outline, l10n.name),
                const SizedBox(height: 8),
                _buildTextFormField(
                  controller: _nameController,
                  hintText: l10n.enterYourName,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (value) => _validateName(value, l10n),
                ),
                const SizedBox(height: 16),

                // ── Delivery address ─────────────────────────────────
                Row(
                  children: [
                    _buildInputLabel(
                      Icons.location_on_outlined,
                      l10n.deliveryAddress,
                    ),
                    const Spacer(),
                    _buildFranceChip(),
                  ],
                ),
                const SizedBox(height: 8),
                _buildAddressField(l10n),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 13,
                      color: Color(0xFF5A91C4),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.addressDetailsHint,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8E98A5),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Grouped detail fields, each clearly labeled.
                _buildMiniLabel(l10n.apartmentSuite),
                _buildTextFormField(
                  controller: _line2Controller,
                  hintText: l10n.apartmentHint,
                  keyboardType: TextInputType.streetAddress,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.meeting_room_outlined,
                ),
                const SizedBox(height: 14),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMiniLabel(l10n.cityLabel),
                          _buildTextFormField(
                            controller: _cityController,
                            hintText: l10n.enterCity,
                            keyboardType: TextInputType.streetAddress,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            prefixIcon: Icons.location_city_rounded,
                            validator: (value) => Validators.required(
                              value,
                              label: l10n.cityLabel,
                              l10n: l10n,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMiniLabel(l10n.postalCodeLabel),
                          _buildTextFormField(
                            controller: _postalController,
                            hintText: l10n.enterPostalCode,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(5),
                            ],
                            validator: (value) => _validatePostalCode(
                              value,
                              l10n,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _buildMiniLabel(l10n.stateRegion),
                _buildTextFormField(
                  controller: _stateController,
                  hintText: l10n.enterStateRegion,
                  keyboardType: TextInputType.streetAddress,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.map_outlined,
                ),
                const SizedBox(height: 16),

                _buildInputLabel(
                  Icons.phone_in_talk_outlined,
                  l10n.phoneNumber,
                ),
                const SizedBox(height: 8),
                _buildPhoneField(l10n),
                const SizedBox(height: 24),

                // Order Summary
                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 16,
                      color: Color(0xFF5A91C4),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.orderSummary,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF243041),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  l10n.subtotal,
                  '\$${subtotal.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  l10n.deliveryFee,
                  '\$${deliveryFee.toStringAsFixed(2)}',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Color(0xFFE8EBF0), height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.total,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF243041),
                      ),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5A91C4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Payment
                Row(
                  children: [
                    const Icon(
                      Icons.payment_outlined,
                      size: 16,
                      color: Color(0xFF5A91C4),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.payment,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF243041),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F8FC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Stripe',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF6772E5),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          _buildPayMethodLogo(
                            'assets/images/payment/card_pay.png',
                          ),
                          const SizedBox(width: 10),
                          // Each platform only shows its own wallet:
                          // Apple Pay on iOS, Google Pay on Android.
                          if (_isApplePlatform)
                            _buildPayMethodLogo(
                              'assets/images/payment/apple_pay.png',
                            )
                          else
                            _buildPayMethodLogo(
                              'assets/images/payment/google_pay.png',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Place Order Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () =>
                              _placeOrder(catalog, subtotal, deliveryFee, total),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A91C4),
                      disabledBackgroundColor: const Color(0xFFB9CFE4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.receipt_long,
                            color: Colors.white,
                            size: 20,
                          ),
                    label: Text(
                      l10n.placeOrder,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF5A91C4)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF243041),
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(String hintText, {Widget? prefixIcon}) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8E98A5)),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: const Color(0xFFF3F8FC),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      errorStyle: const TextStyle(fontSize: 11, color: Color(0xFFE5484D)),
      enabledBorder: border(Colors.transparent, 0),
      focusedBorder: border(const Color(0xFF5A91C4), 1.4),
      errorBorder: border(const Color(0xFFE5484D), 1),
      focusedErrorBorder: border(const Color(0xFFE5484D), 1.4),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction textInputAction = TextInputAction.next,
    List<TextInputFormatter>? inputFormatters,
    IconData? prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontSize: 13, color: Color(0xFF243041)),
      decoration: _fieldDecoration(
        hintText,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, size: 18, color: const Color(0xFF9AA5B1)),
      ),
    );
  }

  /// "🇫🇷 France only" pill next to the address label — signals delivery is
  /// limited to France and matches the France-only suggestion source.
  Widget _buildFranceChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8FC),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFE1E8F0)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🇫🇷', style: TextStyle(fontSize: 12)),
          SizedBox(width: 5),
          Text(
            'France',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5A91C4),
            ),
          ),
        ],
      ),
    );
  }

  String? _validatePostalCode(String? value, AppLocalizations l10n) {
    final requiredMessage = Validators.required(
      value,
      label: l10n.postalCodeLabel,
      l10n: l10n,
    );
    if (requiredMessage != null) {
      return requiredMessage;
    }
    // French postal codes are exactly 5 digits.
    if (!RegExp(r'^\d{5}$').hasMatch(value!.trim())) {
      return l10n.invalidPostalCode;
    }
    return null;
  }

  /// Clears the street search and every auto-filled address part.
  void _clearAddress() {
    setState(() {
      _addressController.clear();
      _line2Controller.clear();
      _cityController.clear();
      _postalController.clear();
      _stateController.clear();
    });
  }

  /// Small caption above a sub-field so each address part is self-explanatory.
  Widget _buildMiniLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6E7784),
        ),
      ),
    );
  }

  /// Auto-fills the structured address fields when the user picks a
  /// suggestion. The street box is always populated — with the street for a
  /// precise address, or the place name for a city/town — so it never ends up
  /// empty (which would leave a stray "required" error after a valid pick).
  void _onAddressSelected(AddressSuggestion s) {
    final streetText = s.street.isNotEmpty ? s.street : s.primary;
    setState(() {
      _addressController.text = streetText;
      if (s.city.isNotEmpty) _cityController.text = s.city;
      if (s.postcode.isNotEmpty) _postalController.text = s.postcode;
      if (s.region.isNotEmpty) _stateController.text = s.region;
    });
    // Setting the controller text re-validates the street field on its own
    // (autovalidateMode.onUserInteraction), so its error clears. Just dismiss
    // the suggestions overlay/keyboard afterwards.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).unfocus();
    });
  }

  Widget _buildAddressField(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldWidth = constraints.maxWidth;
        return Autocomplete<AddressSuggestion>(
          textEditingController: _addressController,
          focusNode: _addressFocus,
          displayStringForOption: (option) => option.fullAddress,
          onSelected: _onAddressSelected,
          optionsBuilder: (textEditingValue) =>
              _addressService.search(textEditingValue.text),
          fieldViewBuilder:
              (context, controller, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.streetAddress,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => onFieldSubmitted(),
                  onChanged: (_) => setState(() {}),
                  validator: (value) => _validateAddress(value, l10n),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF243041),
                  ),
                  decoration:
                      _fieldDecoration(
                        l10n.searchStreetHint,
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: Color(0xFF5A91C4),
                        ),
                      ).copyWith(
                        suffixIcon: controller.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Color(0xFF8E98A5),
                                ),
                                splashRadius: 18,
                                onPressed: _clearAddress,
                              ),
                      ),
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: AlignmentDirectional.topStart,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, child) => Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, (1 - t) * -4),
                      child: child,
                    ),
                  ),
                  child: Material(
                    elevation: 8,
                    color: Colors.white,
                    shadowColor: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      width: fieldWidth,
                      constraints: const BoxConstraints(maxHeight: 280),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE8EBF0)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                            child: Text(
                              l10n.suggestions.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: Color(0xFF8E98A5),
                              ),
                            ),
                          ),
                          Flexible(
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 6),
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                                final highlighted =
                                    AutocompleteHighlightedOption.of(
                                      context,
                                    ) ==
                                    index;
                                return _SuggestionTile(
                                  suggestion: option,
                                  query: _addressController.text,
                                  highlighted: highlighted,
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPhoneField(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CountryCodePicker(
          selected: _country,
          onChanged: (country) {
            setState(() => _country = country);
            // Re-run validation against the newly selected country.
            _formKey.currentState?.validate();
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTextFormField(
            controller: _phoneController,
            hintText: l10n.enterYourPhoneNumber,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(_country.maxDigits),
            ],
            validator: (value) => _validatePhone(value, l10n),
          ),
        ),
      ],
    );
  }

  /// One accepted-payment-method brand logo in the Payment section
  /// (card / Apple Pay / Google Pay).
  Widget _buildPayMethodLogo(String assetPath) {
    return Image.asset(
      assetPath,
      height: 18,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF8E98A5)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF243041),
          ),
        ),
      ],
    );
  }

  String? _validateName(String? value, AppLocalizations l10n) {
    final requiredMessage = Validators.required(
      value,
      label: l10n.name,
      l10n: l10n,
    );
    if (requiredMessage != null) {
      return requiredMessage;
    }
    final trimmed = value!.trim();
    if (trimmed.length < 2) {
      return l10n.minLengthMessage(l10n.name, 2);
    }
    // Letters (incl. accents), spaces, hyphens and apostrophes only.
    final pattern = RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ' -]+$");
    if (!pattern.hasMatch(trimmed)) {
      return l10n.enterValidName;
    }
    return null;
  }

  String? _validateAddress(String? value, AppLocalizations l10n) {
    final requiredMessage = Validators.required(
      value,
      label: l10n.streetAddress,
      l10n: l10n,
    );
    if (requiredMessage != null) {
      return requiredMessage;
    }
    if (value!.trim().length < 3) {
      return l10n.enterCompleteAddress;
    }
    return null;
  }

  String? _validatePhone(String? value, AppLocalizations l10n) {
    final requiredMessage = Validators.required(
      value,
      label: l10n.phoneNumber,
      l10n: l10n,
    );
    if (requiredMessage != null) {
      return requiredMessage;
    }
    final digits = value!.replaceAll(RegExp(r'\D'), '');
    if (digits.length < _country.minDigits) {
      return l10n.phoneTooShort;
    }
    if (digits.length > _country.maxDigits) {
      return l10n.phoneTooLong;
    }
    return null;
  }

  void _placeOrder(
    List<BookItem> catalog,
    double subtotal,
    double deliveryFee,
    double total,
  ) async {
    final l10n = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      showTopToast(context, title: l10n.pleaseFixErrors, type: ToastType.error);
      return;
    }

    final storeState = ref.read(storeControllerProvider);
    if (storeState.cartQuantities.isEmpty) {
      showTopToast(context, title: l10n.cartIsEmpty, type: ToastType.info);
      return;
    }

    final phone = '${_country.dialCode} ${_phoneController.text.trim()}';
    final streetPart = [
      _addressController.text.trim(),
      _line2Controller.text.trim(),
    ].where((p) => p.isNotEmpty).join(', ');
    final cityPart = [
      _postalController.text.trim(),
      _cityController.text.trim(),
    ].where((p) => p.isNotEmpty).join(' ');
    final input = CheckoutInput(
      name: _nameController.text.trim(),
      address: streetPart,
      city: cityPart.isEmpty ? _country.name : cityPart,
      phone: phone,
      paymentMethod: PaymentMethod.stripe,
      line1: _addressController.text.trim(),
      line2: _line2Controller.text.trim(),
      cityName: _cityController.text.trim(),
      postalCode: _postalController.text.trim(),
      state: _stateController.text.trim(),
      countryIso: _country.iso,
    );

    setState(() => _isSubmitting = true);
    final result = await ref
        .read(orderControllerProvider.notifier)
        .placeOrder(
          catalog: catalog,
          quantities: storeState.cartQuantities,
          input: input,
        );

    if (!mounted) return;

    final OrderModel order;
    switch (result) {
      case Success(data: final created):
        order = created;
      case ResultFailure(error: final e):
        setState(() => _isSubmitting = false);
        showTopToast(context, title: e.message, type: ToastType.error);
        return;
    }

    final paid = await _collectPayment(order, total);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (!paid) return;

    ref.read(storeControllerProvider.notifier).clearCart();
    ref.read(orderControllerProvider.notifier).refresh();

    OrderConfirmedSheet.show(
      context,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: total,
      onBackToHome: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }

  Future<bool> _collectPayment(OrderModel order, double total) async {
    final l10n = AppLocalizations.of(context);

    if (kIsWeb || kStripePublishableKey.isEmpty || order.id.isEmpty) {
      showTopToast(
        context,
        title: l10n.paymentsNotConfigured,
        type: ToastType.error,
      );
      return false;
    }

    final intentResult = await ref
        .read(paymentRepositoryProvider)
        .createOrderPayment(orderId: order.id, price: total);
    if (!mounted) return false;

    final PaymentIntentInfo intent;
    switch (intentResult) {
      case Success(data: final info):
        intent = info;
      case ResultFailure(error: final e):
        showTopToast(context, title: e.message, type: ToastType.error);
        return false;
    }

    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: intent.clientSecret,
          merchantDisplayName: 'Books on Wheels',
          style: ThemeMode.light,
          // Only the platform's own wallet is enabled: Apple Pay on
          // iOS/macOS, Google Pay on Android.
          applePay: _isApplePlatform
              ? const PaymentSheetApplePay(merchantCountryCode: 'FR')
              : null,
          googlePay: _isApplePlatform
              ? null
              : PaymentSheetGooglePay(
                  merchantCountryCode: 'FR',
                  currencyCode: 'USD',
                  testEnv: kDebugMode,
                ),
          billingDetails: BillingDetails(
            name: _nameController.text.trim(),
            phone: '${_country.dialCode} ${_phoneController.text.trim()}',
            address: Address(
              line1: _addressController.text.trim(),
              line2: _line2Controller.text.trim(),
              city: _cityController.text.trim(),
              state: _stateController.text.trim(),
              postalCode: _postalController.text.trim(),
              country: _country.iso,
            ),
          ),
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(primary: Color(0xFF5A91C4)),
            shapes: PaymentSheetShape(borderRadius: 12),
            primaryButton: PaymentSheetPrimaryButtonAppearance(
              colors: PaymentSheetPrimaryButtonTheme(
                light: PaymentSheetPrimaryButtonThemeColors(
                  background: Color(0xFF5A91C4),
                ),
              ),
            ),
          ),
        ),
      );
      await Stripe.instance.presentPaymentSheet();
    } on StripeException catch (e) {
      if (!mounted) return false;
      final cancelled = e.error.code == FailureCode.Canceled;
      showTopToast(
        context,
        title: cancelled
            ? l10n.paymentCancelled
            : (e.error.localizedMessage ?? l10n.paymentFailed),
        type: cancelled ? ToastType.info : ToastType.error,
      );
      return false;
    } catch (_) {
      if (!mounted) return false;
      showTopToast(context, title: l10n.paymentFailed, type: ToastType.error);
      return false;
    }

    if (intent.paymentIntentId.isNotEmpty) {
      await ref
          .read(paymentRepositoryProvider)
          .confirmPayment(intent.paymentIntentId);
    }
    return true;
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.suggestion,
    required this.query,
    required this.highlighted,
    required this.onTap,
  });

  final AddressSuggestion suggestion;
  final String query;
  final bool highlighted;
  final VoidCallback onTap;

  TextSpan _highlightSpan(String text) {
    const base = TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w400,
      color: Color(0xFF243041),
    );
    const bold = TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w700,
      color: Color(0xFF243041),
    );
    final q = query.trim();
    if (q.isEmpty) {
      return TextSpan(text: text, style: base);
    }
    final index = text.toLowerCase().indexOf(q.toLowerCase());
    if (index < 0) {
      return TextSpan(text: text, style: base);
    }
    return TextSpan(
      children: [
        TextSpan(text: text.substring(0, index), style: base),
        TextSpan(text: text.substring(index, index + q.length), style: bold),
        TextSpan(text: text.substring(index + q.length), style: base),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: highlighted ? const Color(0xFFF3F8FC) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F8FC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                suggestion.isCity
                    ? Icons.location_city_rounded
                    : Icons.place_outlined,
                size: 18,
                color: const Color(0xFF5A91C4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: _highlightSpan(suggestion.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    suggestion.secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF8E98A5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
