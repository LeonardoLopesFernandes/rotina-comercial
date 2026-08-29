import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void showToast(String message, [bool long = false]) {
  final messenger = scaffoldMessengerKey.currentState;
  if (messenger == null) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: long ? const Duration(seconds: 4) : const Duration(seconds: 2),
    ),
  );
}
