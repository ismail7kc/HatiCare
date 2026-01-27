import 'package:flutter/material.dart';

class ShimmerEffect extends StatelessWidget {
  final Widget? child;
  final double width;
  final double height;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerEffect({
    super.key,
    this.child,
    this.width = double.infinity,
    this.height = 60.0,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
  });

  @override
  Widget build(BuildContext context) {
    return _ShimmerLoading(
      width: width,
      height: height,
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}

class _ShimmerLoading extends StatefulWidget {
  final Widget? child;
  final double width;
  final double height;
  final Color baseColor;
  final Color highlightColor;

  const _ShimmerLoading({
    required this.width,
    required this.height,
    required this.baseColor,
    required this.highlightColor,
    this.child,
  });

  @override
  State<_ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<_ShimmerLoading>
  with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut));
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, _) {
        return _buildShimmer(
          value: _shimmerAnimation.value,
          baseColor: widget.baseColor,
          highlightColor: widget.highlightColor,
          width: widget.width,
          height: widget.height,
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }

  Widget _buildShimmer({
    required double value,
    required Color baseColor,
    required Color highlightColor,
    required double width,
    required double height,
    required Widget? child,
  }) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          baseColor,
          highlightColor,
          baseColor,
          highlightColor,
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
        begin: Alignment(-1.0 + value, 0.0),
        end: Alignment(1.0 + value, 0.0),
      ).createShader(bounds),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: child,
      ),
    );
  }
}
