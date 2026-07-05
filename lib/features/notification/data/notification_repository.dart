import '../../../core/errors/result.dart';
import '../../../core/network/api_client.dart';
import '../domain/notification_models.dart';

final class NotificationRepository {
  const NotificationRepository(this._client);

  final ApiClient _client;

  Future<Result<NotificationsPageData>> getMyNotifications({
    int page = 1,
    int limit = 20,
  }) {
    return _client.get<NotificationsPageData>(
      '/notification',
      queryParameters: {'page': page, 'limit': limit},
      parser: (data) {
        if (data is! Map<String, dynamic>) {
          throw Exception('Invalid notifications response');
        }
        if (data['success'] == false) {
          throw Exception(data['message']?.toString() ?? 'Request failed');
        }

        final rootData = data['data'] as Map<String, dynamic>? ?? {};
        final notifications =
            (rootData['notifications'] as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>()
                .map(AppNotification.fromJson)
                .toList(growable: false);

        return NotificationsPageData(
          items: notifications,
          unreadCount: (rootData['unreadCount'] as num?)?.toInt() ?? 0,
        );
      },
    );
  }

  Future<Result<int>> getUnreadCount() {
    return _client.get<int>(
      '/notification/unread-count',
      parser: (data) {
        if (data is! Map<String, dynamic>) {
          throw Exception('Invalid unread count response');
        }
        if (data['success'] == false) {
          throw Exception(data['message']?.toString() ?? 'Request failed');
        }
        final rootData = data['data'] as Map<String, dynamic>? ?? {};
        return (rootData['unreadCount'] as num?)?.toInt() ?? 0;
      },
    );
  }

  Future<Result<void>> markAsRead(String id) async {
    final result = await _client.patch<dynamic>('/notification/$id/read');
    return switch (result) {
      Success() => const Success(null),
      ResultFailure(error: final e) => ResultFailure(e),
    };
  }

  Future<Result<void>> markAllAsRead() async {
    final result = await _client.patch<dynamic>('/notification/read-all');
    return switch (result) {
      Success() => const Success(null),
      ResultFailure(error: final e) => ResultFailure(e),
    };
  }

  /// The backend exposes no device-token or push-preference routes, so FCM
  /// token registration is a local no-op and the push toggle is persisted
  /// on-device (see profile tab). If the backend gains
  /// `POST /notification/device-token` later, call it from here.
  Future<Result<void>> registerDeviceToken(String token) async {
    return const Success(null);
  }

  /// See [registerDeviceToken] — nothing to remove server-side.
  Future<Result<void>> removeDeviceToken(String token) async {
    return const Success(null);
  }
}
