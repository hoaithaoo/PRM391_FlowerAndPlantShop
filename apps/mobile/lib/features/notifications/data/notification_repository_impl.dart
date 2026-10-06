import '../models/notification_list_result.dart';
import '../models/notification_read_result.dart';
import 'notification_failure.dart';
import 'notification_remote_data_source.dart';
import 'notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._remoteDataSource);

  final NotificationRemoteDataSource _remoteDataSource;

  @override
  Future<NotificationListResult> getNotifications({
    int page = 1,
    bool unreadOnly = false,
  }) async {
    final response = await _remoteDataSource.getNotifications(
      page: page,
      unreadOnly: unreadOnly,
    );

    try {
      return NotificationListResult.fromApiResponse(response);
    } catch (_) {
      throw const NotificationFailure(
        code: NotificationErrorCode.malformedResponse,
      );
    }
  }

  @override
  Future<NotificationReadResult> markAsRead(String notificationId) async {
    final response = await _remoteDataSource.markAsRead(notificationId);
    try {
      return NotificationReadResult.fromJson(response);
    } catch (_) {
      throw const NotificationFailure(
        code: NotificationErrorCode.malformedResponse,
      );
    }
  }

  @override
  Future<int> markAllAsRead() async {
    final response = await _remoteDataSource.markAllAsRead();
    final updatedCount = response['updatedCount'];
    if (updatedCount is num && updatedCount >= 0) {
      return updatedCount.toInt();
    }
    throw const NotificationFailure(
      code: NotificationErrorCode.malformedResponse,
    );
  }
}
