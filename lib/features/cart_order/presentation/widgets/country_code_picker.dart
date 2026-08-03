import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/country_codes.dart';

/// A compact pill that shows the selected dialing code and opens a searchable
/// country sheet on tap. Designed to sit inline with the phone text field.
class CountryCodePicker extends StatelessWidget {
  const CountryCodePicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.hasError = false,
  });

  final CountryCode selected;
  final ValueChanged<CountryCode> onChanged;
  final bool hasError;

  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<CountryCode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CountrySheet(selected: selected),
    );
    if (result != null) {
      onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? const Color(0xFFE5484D)
        : const Color(0xFFE8EBF0);
    return Material(
      color: const Color(0xFFF3F8FC),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _open(context),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(selected.flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                selected.dialCode,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF243041),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: Color(0xFF8E98A5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountrySheet extends StatefulWidget {
  const _CountrySheet({required this.selected});

  final CountryCode selected;

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = _query.trim().toLowerCase();
    final results = query.isEmpty
        ? kCountryCodes
        : kCountryCodes
              .where((c) => c.searchable.contains(query))
              .toList(growable: false);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EBF0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.public_rounded,
                        size: 20,
                        color: Color(0xFF5A91C4),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.selectCountry,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF243041),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF243041),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: l10n.searchCountry,
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF8E98A5),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF3F8FC),
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: results.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noCountryFound,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8E98A5),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final country = results[index];
                            final isSelected =
                                country.iso == widget.selected.iso;
                            return ListTile(
                              onTap: () => Navigator.of(context).pop(country),
                              leading: Text(
                                country.flag,
                                style: const TextStyle(fontSize: 24),
                              ),
                              title: Text(
                                country.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF243041),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    country.dialCode,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF8E98A5),
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 18,
                                      color: Color(0xFF5A91C4),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
