import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Device back-button handling for a bottom-navigation dashboard shell.
///
/// Behaviour (shared across all SOS apps):
///  * Not on the first/home tab        -> switch to the first tab (no exit).
///  * On the first tab, 1st back press  -> "Press back again to exit" toast.
///  * On the first tab, 2nd back <2s    -> confirmation dialog -> exit app.
///
/// Usage: mix into the bottom-nav shell State, implement [selectedTabIndex] and
/// [onBackToFirstTab], and wrap the shell Scaffold in a single
/// `PopScope(canPop: false, onPopInvoked: handleDashboardPop, child: ...)`.
mixin DashboardBackHandler<T extends StatefulWidget> on State<T> {
  DateTime? _lastBackPress;

  /// Index of the home/first tab. Override only if it is not 0.
  int get firstTabIndex => 0;

  /// Current selected tab index in the shell.
  int get selectedTabIndex;

  /// Move the shell to the first/home tab (usually a setState).
  void onBackToFirstTab();

  /// Wire this to `PopScope.onPopInvoked`.
  Future<void> handleDashboardPop(bool didPop) async {
    if (didPop) return;

    // Not on the home tab -> go to the home tab instead of exiting.
    if (selectedTabIndex != firstTabIndex) {
      onBackToFirstTab();
      return;
    }

    // First back press (or after the 2s window lapsed): warn, do not exit.
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit'),
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }

    // Second back press within 2s -> confirm, then exit.
    final shouldExit = await _confirmExit();
    if (shouldExit) {
      await SystemNavigator.pop();
    } else {
      _lastBackPress = null; // reset the window after a cancel
    }
  }

  Future<bool> _confirmExit() async {
    if (!mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to close the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
