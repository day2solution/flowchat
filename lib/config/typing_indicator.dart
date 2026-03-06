import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Theme Colors from your Unique Design
  final Color purpleColor = const Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(int index, double screenWidth) {
    // Create a staggered wave effect (0.0 to 1.0)
    final delay = index * 0.2;
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(delay, 0.6 + delay, curve: Curves.easeInOut),
    );

    // Scaling the dot based on screen width
    final double dotSize = (screenWidth * 0.015).clamp(4.0, 7.0);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          width: dotSize,
          height: dotSize,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            // Modern syntax: withValues instead of withOpacity
            color: purpleColor.withValues(alpha: 0.3 + (0.7 * animation.value)),
            shape: BoxShape.circle,
            boxShadow: [
              // Subtle glow effect matching the dot's intensity
              BoxShadow(
                color: purpleColor.withValues(alpha: 0.2 * animation.value),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              vertical: (screenWidth * 0.03).clamp(10.0, 16.0),
              horizontal: (screenWidth * 0.04).clamp(14.0, 20.0),
            ),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
                bottomRight: Radius.circular(22),
                bottomLeft: Radius.circular(6), // Consistent "Unique" tail
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0, screenWidth),
                _buildDot(1, screenWidth),
                _buildDot(2, screenWidth),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
