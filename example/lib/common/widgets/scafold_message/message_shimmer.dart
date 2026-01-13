import 'package:flutter/material.dart';

/// Message widget with loading spinner shader animation
class MessageShimmer extends StatelessWidget {
  const MessageShimmer({
    super.key,
    required this.message,
    this.color,
  });

  final String message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final spinnerColor = color ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: spinnerColor.withAlpha(100),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: spinnerColor.withAlpha(51),
              blurRadius: 12.0,
              offset: Offset(0, 4.0),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 32.0,
                width: 32.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                ),
              ),
              SizedBox(width: 16.0),
              Flexible(
                child: Text(
                  message,
                  style: TextStyle(
                    color: spinnerColor,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
