import 'dart:async';
import 'package:flutter/material.dart';
import 'package:road_helperr/ui/screens/otp_expired_screen.dart';
import 'package:road_helperr/utils/app_colors.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  int _seconds = 59;
  Timer? _timer;

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() {
          _seconds--;
          if (_seconds == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OtpExpiredScreen()),
            );
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "00:$_seconds",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.getOtpFieldColor(context), // ديناميك مع الثيم
        ),
      ),
    );
  }
}
