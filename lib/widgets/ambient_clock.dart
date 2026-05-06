import 'dart:async';

import 'package:flutter/material.dart';

class AmbientClock extends StatefulWidget {
  const AmbientClock({super.key});

  @override
  State<AmbientClock> createState() => _AmbientClockState();
}

class _AmbientClockState extends State<AmbientClock> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          '$h:$m',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white24,
              ),
        ),
      ),
    );
  }
}
