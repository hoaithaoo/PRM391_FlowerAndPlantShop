import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC Observer used to log state transitions and events.
/// Rất hữu ích khi demo trước giảng viên PRM393 để minh chứng luồng State Management.
class AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    debugPrint('⚡ [BLoC Event] ${bloc.runtimeType} -> $event');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    debugPrint('🔄 [BLoC Change] ${bloc.runtimeType} -> currentState: ${change.currentState.runtimeType}, nextState: ${change.nextState.runtimeType}');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    debugPrint('🚀 [BLoC Transition] ${bloc.runtimeType} -> Event: ${transition.event.runtimeType} | State: ${transition.nextState.runtimeType}');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    debugPrint('❌ [BLoC Error] ${bloc.runtimeType} -> $error');
    super.onError(bloc, error, stackTrace);
  }
}
