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

  static Future<void> waitUntilAppReady({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (_appReadyCompleter.isCompleted) {
      return;
    }

    await _appReadyCompleter.future.timeout(
      timeout,
      onTimeout: () {
        debugPrint('NavigationService: terminó el tiempo de espera.');
      },
    );
  }

  static Future<T?> push<T>(Route<T> route) {
    final NavigatorState? navigatorState = navigator;

    if (navigatorState == null) {
      return Future<T?>.value(null);
    }

    return navigatorState.push<T>(route);
  }

  static Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    final NavigatorState? navigatorState = navigator;

    if (navigatorState == null) {
      return Future<T?>.value(null);
    }

    return navigatorState.pushNamed<T>(routeName, arguments: arguments);
  }
}
