import 'package:flutter_riverpod/flutter_riverpod.dart';

final sessionExpiryProvider = NotifierProvider<SessionExpiryController, int>(
  SessionExpiryController.new,
);

final class SessionExpiryController extends Notifier<int> {
  @override
  int build() => 0;

  void notifyExpired() {
    state++;
  }
}
