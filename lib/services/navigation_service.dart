import 'package:flutter/material.dart';

class NavigationService {
  NavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  static NavigatorState? get navigator =>
      navigatorKey.currentState;

  static Future<T?> push<T>(
      Route<T> route,
      ) {
    final NavigatorState? navigatorState = navigator;

    if (navigatorState == null) {
      return Future<T?>.value(null);
    }

    return navigatorState.push<T>(route);
  }

  static Future<T?> pushNamed<T>(
      String routeName, {
        Object? arguments,
      }) {
    final NavigatorState? navigatorState = navigator;

    if (navigatorState == null) {
      return Future<T?>.value(null);
    }

    return navigatorState.pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }
}