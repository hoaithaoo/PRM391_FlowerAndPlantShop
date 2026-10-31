import 'package:flutter/widgets.dart';

import 'auth_repository.dart';

/// Cung cấp [AuthRepository] cho các màn auth qua cây widget.
class AuthScope extends InheritedWidget {
  const AuthScope({super.key, required this.repository, required super.child});

  final AuthRepository repository;

  static AuthRepository of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'Không tìm thấy AuthScope phía trên widget này.');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(AuthScope oldWidget) {
    return repository != oldWidget.repository;
  }
}
