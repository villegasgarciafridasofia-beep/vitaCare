import 'dart:async';

import 'package:flutter/material.dart';

class NavigationService {
  NavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Completer<void> _appReadyCompleter = Completer<void>();

  static NavigatorState? get navigator => navigatorKey.currentState;

  static bool get isAppReady => _appReadyCompleter.isCompleted;

  static void markAppReady() {
    if (!_appReadyCompleter.isCompleted) {
      _appReadyCompleter.complete();
      debugPrint('NavigationService: aplicación lista para navegar.');
    }
  }

  static void resetAppReady() {
    if (_appReadyCompleter.isCompleted) {
      _appReadyCompleter = Completer<void>();
      debugPrint('NavigationService: estado de navegación reiniciado.');
    }
  }

  static Future<void> waitUntilAppReady({
    Duration timeout = const Duration(seconds: 25),
  }) async {
    if (_appReadyCompleter.isCompleted) return;

    try {
      await _appReadyCompleter.future.timeout(timeout);
    } on TimeoutException {
      debugPrint('NavigationService: terminó el tiempo de espera.');
    }
  }

  static Future<T?> push<T>(Route<T> route) {
    final NavigatorState? navigatorState = navigator;
    if (navigatorState == null) return Future<T?>.value(null);
    return navigatorState.push<T>(route);
  }

  static Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    final NavigatorState? navigatorState = navigator;
    if (navigatorState == null) return Future<T?>.value(null);
    return navigatorState.pushNamed<T>(routeName, arguments: arguments);
  }
}
