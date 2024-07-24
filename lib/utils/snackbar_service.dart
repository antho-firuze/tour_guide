import 'package:flutter/material.dart';
import 'package:tour_guide/main.dart';

class SnackBarService {
  static void show({
    required String message,
    Duration? duration,
  }) {
    scaffoldKey.currentState!.showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

extension SnackBarExt on BuildContext {
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}
