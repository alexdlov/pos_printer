import 'package:flutter/material.dart';
import 'animated_message_card.dart';

enum ScfMessageType { loading, success, failure }

class ScfMessage extends StatelessWidget {
  const ScfMessage({
    super.key,
    required this.errorMessage,
    required this.messageType,
    this.duration = const Duration(seconds: 3),
  });

  final String errorMessage;
  final ScfMessageType messageType;
  final Duration duration;

  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  static void show(
    BuildContext context, {
    required String message,
    required ScfMessageType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: type == ScfMessageType.loading
            ? const Duration(seconds: 6)
            : duration,
        padding: EdgeInsets.only(bottom: 100.0),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 400.0,
              maxWidth: 600.0,
            ),
            child: AnimatedMessageCard(
              message: message,
              messageType: type,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    show(
      context,
      message: errorMessage,
      type: messageType,
      duration: duration,
    );
    return const SizedBox.shrink();
  }
}
