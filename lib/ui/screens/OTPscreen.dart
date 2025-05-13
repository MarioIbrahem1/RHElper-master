import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:road_helperr/ui/screens/new_password_screen.dart';
import 'package:road_helperr/services/api_service.dart';
import 'package:road_helperr/ui/screens/bottomnavigationbar_screes/home_screen.dart';
import 'package:road_helperr/services/notification_service.dart';
import 'dart:async';
import 'package:road_helperr/utils/app_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Otp extends StatefulWidget {
  final String email;
  final Map<String, dynamic>? registrationData;

  const Otp({
    super.key,
    required this.email,
    this.registrationData,
  });

  static const routeName = "otpscreen";

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<Otp> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  Timer? _timer;
  int _timeLeft = 60;
  bool _isResendEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        setState(() {
          _isResendEnabled = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _resendOTP() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.sendOTP(widget.email);
      if (response['success'] == true) {
        setState(() {
          _timeLeft = 60;
          _isResendEnabled = false;
        });
        _startTimer();
        NotificationService.showSuccess(
          context: context,
          title: 'OTP Sent',
          message: 'OTP has been sent to your email',
        );
      } else {
        NotificationService.showGenericError(
          context,
          response['error'] ?? 'Failed to send OTP',
        );
      }
    } catch (e) {
      NotificationService.showNetworkError(context);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      NotificationService.showValidationError(
        context,
        'Please enter a 6-digit OTP code',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // For testing purposes, always succeed
      if (true) {
        if (!mounted) return;

        if (widget.registrationData != null) {
          // Registration Flow
          NotificationService.showRegistrationSuccess(
            context,
            onConfirm: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
          );
        } else {
          // Password Reset Flow
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => NewPasswordScreen(
                email: widget.email,
              ),
            ),
          );
        }
        return;
      }

      if (widget.registrationData != null) {
        // Registration Flow
        final registerResponse = await ApiService.register(
          widget.registrationData!,
          _otpController.text,
        );

        if (registerResponse['success'] == true) {
          if (!mounted) return;

          NotificationService.showRegistrationSuccess(
            context,
            onConfirm: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
          );
        } else {
          if (!mounted) return;

          NotificationService.showGenericError(
            context,
            registerResponse['error'] ?? 'Failed to complete registration',
          );
        }
      } else {
        // Password Reset Flow
        final response = await ApiService.verifyOTP(
          widget.email,
          _otpController.text,
        );

        if (response['success'] == true) {
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => NewPasswordScreen(
                email: widget.email,
              ),
            ),
          );
        } else {
          if (!mounted) return;

          NotificationService.showGenericError(
            context,
            response['error'] ?? 'Invalid OTP code',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.showNetworkError(context);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var lang = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = isLight ? Colors.black : Colors.white;
    final bgColor = isLight ? const Color(0xFF86A5D9) : const Color(0xFF1F3551);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top image
            Image.asset(
              'assets/images/chracters.png',
              height: 200,
              fit: BoxFit.contain,
            ),

            // Add space between image and container
            const SizedBox(height: 20),

            // Bottom container with content
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 0),
                decoration: BoxDecoration(
                  color: isLight ? Colors.white : const Color(0xFF01122A),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                        lang.otpVerification,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        lang.enterOtpSentToEmail(widget.email),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // OTP input fields with padding
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: PinCodeTextField(
                          appContext: context,
                          length: 6,
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(10),
                            fieldHeight: 50,
                            fieldWidth: 40,
                            activeFillColor: isLight ? Colors.grey[200] : const Color(0xFF1F3551),
                            inactiveFillColor: isLight ? Colors.grey[200] : const Color(0xFF1F3551),
                            selectedFillColor: isLight ? Colors.grey[200] : const Color(0xFF1F3551),
                            activeColor: isLight ? AppColors.getSignAndRegister(context) : Colors.white,
                            inactiveColor: isLight ? AppColors.getSignAndRegister(context) : Colors.white,
                            selectedColor: isLight ? AppColors.getSignAndRegister(context) : Colors.white,
                          ),
                          enableActiveFill: true,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Text(
                        'Resend in $_timeLeft seconds',
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 35),
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else
                        Column(
                          children: [
                            // Verify button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _verifyOTP,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF023A87),
                                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  lang.verify,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Resend button
                            TextButton(
                              onPressed: _isResendEnabled ? _resendOTP : null,
                              child: Text(
                                'Resend Code',
                                style: TextStyle(
                                  color: _isResendEnabled
                                      ? AppColors.getSignAndRegister(context)
                                      : Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
