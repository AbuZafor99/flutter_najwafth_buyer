import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/result.dart';
import '../../../core/network/network_providers.dart';
import '../../auth/application/auth_controller.dart';

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, ProfileState>(
      ProfileController.new,
    );

final class ProfileState {
  const ProfileState({
    required this.name,
    required this.email,
    required this.phone,
    required this.bio,
    required this.gender,
    required this.dob,
    required this.age,
    required this.address,
    required this.avatarUrl,
  });

  const ProfileState.empty()
    : name = '',
      email = '',
      phone = '',
      bio = '',
      gender = '',
      dob = '',
      age = null,
      address = '',
      avatarUrl = '';

  final String name;
  final String email;
  final String phone;
  final String bio;
  final String gender;
  final String dob;
  final int? age;
  final String address;
  final String avatarUrl;

  ProfileState copyWith({
    String? name,
    String? email,
    String? phone,
    String? bio,
    String? gender,
    String? dob,
    int? age,
    String? address,
    String? avatarUrl,
  }) {
    return ProfileState(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      age: age ?? this.age,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

final class ProfileController extends AsyncNotifier<ProfileState> {
  @override
  Future<ProfileState> build() async {
    return _fetchProfile();
  }

  Future<void> refreshProfile() async {
    state = const AsyncLoading<ProfileState>();
    state = await AsyncValue.guard(_fetchProfile);
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String bio,
    required String gender,
    required String dob,
    required String age,
    required String address,
    String? avatarPath,
  }) async {
    final token = _authToken;
    if (token == null || token.isEmpty) {
      throw const AuthFlowException('Please sign in again.');
    }

    // gender/dob/age are typed on the backend (enum/Date/Number), so empty
    // values are omitted instead of sent as empty strings.
    final fields = <String, dynamic>{
      'name': name.trim(),
      'phone': phone.trim(),
      'bio': bio.trim(),
      if (gender.trim().isNotEmpty) 'gender': gender.trim(),
      if (dob.trim().isNotEmpty) 'dob': dob.trim(),
      if (age.trim().isNotEmpty) 'age': age.trim(),
      'address': address.trim(),
    };

    final payload = FormData.fromMap({
      ...fields,
      if (avatarPath != null && avatarPath.trim().isNotEmpty)
        'avatar': await MultipartFile.fromFile(
          avatarPath,
          filename: avatarPath.split('/').last,
        ),
    });

    final options = Options(
      headers: {'Authorization': 'Bearer $token'},
      contentType: 'multipart/form-data',
    );

    final result = await ref
        .read(apiClientProvider)
        .patch<ProfileState>(
          '/user/me',
          data: payload,
          options: options,
          parser: _extractProfileData,
        );

    final updated = _unwrapProfile(result);
    state = AsyncValue.data(updated);

    await refreshProfile();

    await ref
        .read(authControllerProvider.notifier)
        .updateProfileBasics(fullName: updated.name, phone: updated.phone);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final token = _authToken;
    if (token == null || token.isEmpty) {
      throw const AuthFlowException('Please sign in again.');
    }

    final result = await ref
        .read(apiClientProvider)
        .patch<ProfileState>(
          '/user/change-password',
          data: {
            'currentPassword': currentPassword,
            'newPassword': newPassword,
            'confirmPassword': confirmPassword,
          },
          options: Options(headers: {'Authorization': 'Bearer $token'}),
          parser: _extractProfileData,
        );
    _unwrapProfile(result);
  }

  String? get _authToken => ref.read(authControllerProvider).accessToken;

  Future<ProfileState> _fetchProfile() async {
    final token = _authToken;
    if (token == null || token.isEmpty) {
      return const ProfileState.empty();
    }

    final result = await ref
        .read(apiClientProvider)
        .get<ProfileState>(
          '/user/me',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
          parser: _extractProfileData,
        );
    final profile = _unwrapProfile(result);

    await ref
        .read(authControllerProvider.notifier)
        .updateProfileBasics(fullName: profile.name, phone: profile.phone);

    return profile;
  }
}

ProfileState _extractProfileData(dynamic raw) {
  if (raw is! Map<String, dynamic>) {
    throw const AuthFlowException('Unexpected server response.');
  }
  if (raw['success'] == false) {
    throw AuthFlowException(
      (raw['message'] ?? 'Request could not be completed.').toString(),
    );
  }

  final data = raw['data'];
  if (data is! Map<String, dynamic>) {
    return const ProfileState.empty();
  }

  final avatar = data['avatar'];
  final avatarMap = avatar is Map<String, dynamic> ? avatar : null;

  return ProfileState(
    name: (data['name'] ?? '').toString(),
    email: (data['email'] ?? '').toString(),
    phone: (data['phone'] ?? '').toString(),
    bio: (data['bio'] ?? '').toString(),
    gender: (data['gender'] ?? '').toString(),
    dob: (data['dob'] ?? '').toString(),
    age: data['age'] is int ? data['age'] as int : null,
    address: (data['address'] ?? '').toString(),
    avatarUrl: (avatarMap?['url'] ?? '').toString(),
  );
}

ProfileState _unwrapProfile(Result<ProfileState> result) {
  return switch (result) {
    Success(data: final data) => data,
    ResultFailure(error: final error) => throw AuthFlowException(error.message),
  };
}
