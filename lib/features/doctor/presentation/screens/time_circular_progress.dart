import 'dart:async';
import 'package:flutter/material.dart';

class TimedCircularProgress extends StatefulWidget {
  final int totalSeconds;
  final double size;
  final Color color;
  final Color backgroundColor;
  final void Function()? onComplete;

  final double? initialProgress;
  final int? initialSecondsLeft;

  const TimedCircularProgress({
    super.key,
    required this.totalSeconds,
    this.size = 40,
    this.color = const Color(0xFF34C759),
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.onComplete,
    this.initialProgress,
    this.initialSecondsLeft,
  });

  @override
  State<TimedCircularProgress> createState() => _TimedCircularProgressState();
}

class _TimedCircularProgressState extends State<TimedCircularProgress> {
  late double progress;
  late int secondsLeft;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    progress = widget.initialProgress ?? 1.0;
    secondsLeft = widget.initialSecondsLeft ?? widget.totalSeconds;

    if (widget.initialProgress == null) {
      timer = Timer.periodic(const Duration(milliseconds: 15), (timer) {
        setState(() {
          progress -= 15 / 1000 / widget.totalSeconds;
          if (progress <= 0) {
            progress = 0;
            secondsLeft = 0;
            timer.cancel();
            widget.onComplete?.call();
          } else {
            secondsLeft = (progress * widget.totalSeconds).ceil();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: 4,
            backgroundColor: widget.backgroundColor,
            color: widget.color,
          ),
        ),
        Text(
          "$secondsLeft",
          style: TextStyle(
            fontSize: widget.size / 3.5,
            fontWeight: FontWeight.bold,
            color: widget.color,
          ),
        ),
      ],
    );
  }
}
