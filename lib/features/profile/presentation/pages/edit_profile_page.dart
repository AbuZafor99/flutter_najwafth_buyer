import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/top_toast.dart';
import '../../application/profile_controller.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _genderController = TextEditingController();
  final _dobController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();

  final _picker = ImagePicker();
  bool _didInit = false;
  bool _isSaving = false;
  String? _selectedAvatarPath;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _genderController.dispose();
    _dobController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initFromProfileIfNeeded();
  }

  void _initFromProfileIfNeeded() {
    if (_didInit) {
      return;
    }
    final profile = ref.read(profileControllerProvider).asData?.value;
    if (profile == null) {
      return;
    }

    _nameController.text = profile.name;
    _phoneController.text = profile.phone;
    _bioController.text = profile.bio;
    _genderController.text = profile.gender;
    _dobController.text = _toYmd(profile.dob);
    _ageController.text = profile.age?.toString() ?? '';
    _addressController.text = profile.address;
    _didInit = true;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(profileControllerProvider.notifier)
          .updateProfile(
            name: _nameController.text,
            phone: _phoneController.text,
            bio: _bioController.text,
            gender: _genderController.text,
            dob: _dobController.text,
            age: _ageController.text,
            address: _addressController.text,
            avatarPath: _selectedAvatarPath,
          );

      if (!mounted) {
        return;
      }

      _showMessage(
        AppLocalizations.of(context).profileUpdated,
        type: ToastType.success,
      );
      Navigator.pop(context);
    } on Exception catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickAvatar() async {
    final source = await _showImageSourceSheet();
    if (source == null) {
      return;
    }

    try {
      final file = await _picker.pickImage(source: source, imageQuality: 80);
      if (file == null || !mounted) {
        return;
      }
      setState(() => _selectedAvatarPath = file.path);
    } on Exception catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<ImageSource?> _showImageSourceSheet() {
    final l10n = AppLocalizations.of(context);
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.chooseFromGallery),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(l10n.takeAPhoto),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMessage(String message, {ToastType type = ToastType.error}) {
    showTopToast(context, title: message, type: type);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(profileControllerProvider);
    final profile = profileAsync.asData?.value;
    _initFromProfileIfNeeded();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F8FC),
        surfaceTintColor: const Color(0xFFF7F8FC),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.chevron_left,
            color: Color(0xFF243041),
            size: 28,
          ),
        ),
        title: Text(
          l10n.editProfile,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF243041),
          ),
        ),
      ),
      body: profileAsync.isLoading && profile == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5A91C4)),
            )
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      children: [
                        _buildHeroCard(profile, l10n),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          title: l10n.basicInfo,
                          children: [
                            _buildInput(
                              label: l10n.fullNameLabel,
                              controller: _nameController,
                              hint: l10n.fullNamePlaceholder,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? l10n.requiredMessage(l10n.fullNameLabel)
                                  : null,
                            ),
                            _buildInput(
                              label: l10n.phoneNumber,
                              controller: _phoneController,
                              hint: l10n.enterYourPhoneNumber,
                              keyboardType: TextInputType.phone,
                            ),
                            _buildInput(
                              label: l10n.address,
                              controller: _addressController,
                              hint: l10n.enterYourAddress,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildSectionCard(
                          title: l10n.personalInfo,
                          children: [
                            _buildInput(
                              label: l10n.genderLabel,
                              controller: _genderController,
                              hint: l10n.genderHint,
                            ),
                            _buildInput(
                              label: l10n.dobLabel,
                              controller: _dobController,
                              hint: 'YYYY-MM-DD',
                              validator: (v) {
                                final value = (v ?? '').trim();
                                if (value.isEmpty) return null;
                                final ok = RegExp(
                                  r'^\d{4}-\d{2}-\d{2}$',
                                ).hasMatch(value);
                                return ok ? null : l10n.useYmdFormat;
                              },
                            ),
                            _buildInput(
                              label: l10n.ageLabel,
                              controller: _ageController,
                              hint: l10n.enterAge,
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                final value = (v ?? '').trim();
                                if (value.isEmpty) return null;
                                return int.tryParse(value) == null
                                    ? l10n.ageMustBeNumber
                                    : null;
                              },
                            ),
                            _buildInput(
                              label: l10n.bioLabel,
                              controller: _bioController,
                              hint: l10n.writeYourBio,
                              maxLines: 4,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFE6EAF0))),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A91C4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                l10n.saveChanges,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroCard(ProfileState? profile, AppLocalizations l10n) {
    final imageProvider = _selectedAvatarPath != null
        ? FileImage(File(_selectedAvatarPath!))
        : ((profile?.avatarUrl.isNotEmpty ?? false)
                  ? NetworkImage(profile!.avatarUrl)
                  : const AssetImage('assets/images/profile_placeholder.png'))
              as ImageProvider;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE8EBF0), width: 1),
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: IconButton(
                  onPressed: _pickAvatar,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF5A91C4),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.trim().isEmpty
                      ? l10n.yourNamePlaceholder
                      : _nameController.text.trim(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF243041),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  (profile?.email ?? '').trim().isEmpty
                      ? 'your@email.com'
                      : profile!.email.trim(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7B8797),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.tapCameraToUpdateAvatar,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5A91C4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF243041),
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5E6B7A),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFFF8FAFD),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE8EBF0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE8EBF0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF5A91C4)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _toYmd(String value) {
    if (value.isEmpty) return '';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}-$month-$day';
  }
}
