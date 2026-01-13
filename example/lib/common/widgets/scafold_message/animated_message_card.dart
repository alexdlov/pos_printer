import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pos_printer_example/common/widgets/scafold_message/message_shimmer.dart';
import 'package:pos_printer_example/common/widgets/scafold_message/scf_message.dart';

class AnimatedMessageCard extends StatefulWidget {
  const AnimatedMessageCard({
    super.key,
    required this.message,
    required this.messageType,
  });

  final String message;
  final ScfMessageType messageType;

  @override
  State<AnimatedMessageCard> createState() => _AnimatedMessageCardState();
}

class _AnimatedMessageCardState extends State<AnimatedMessageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    final colorScheme = Theme.of(context).colorScheme;
    switch (widget.messageType) {
      case ScfMessageType.success:
        return colorScheme.surface.withAlpha(230);
      case ScfMessageType.failure:
        return colorScheme.error.withAlpha(230);
      case ScfMessageType.loading:
        return colorScheme.surface.withAlpha(230);
    }
  }

  Color _getBorderColor() {
    final colorScheme = Theme.of(context).colorScheme;
    switch (widget.messageType) {
      case ScfMessageType.success:
        return colorScheme.primary;
      case ScfMessageType.failure:
        return colorScheme.error;
      case ScfMessageType.loading:
        return CupertinoColors.systemBlue;
    }
  }

  IconData _getIcon() {
    switch (widget.messageType) {
      case ScfMessageType.success:
        return Icons.check_circle;
      case ScfMessageType.failure:
        return Icons.error;
      case ScfMessageType.loading:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use shader animation for loading messages
    if (widget.messageType == ScfMessageType.loading) {
      return SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: MessageShimmer(
              message: widget.message,
              color: _getBorderColor(),
            ),
          ),
        ),
      );
    }

    // Standard animation for success/failure
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SizedBox(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: _getBorderColor(),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getBorderColor().withAlpha(77),
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
                    Icon(
                      _getIcon(),
                      color: _getBorderColor(),
                      size: 28.0,
                    ),
                    SizedBox(width: 12.0),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
