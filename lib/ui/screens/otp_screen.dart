import 'dart:async';
import 'package:flutter/material.dart';
import 'package:road_helperr/ui/screens/bottomnavigationbar_screes/home_screen.dart';
import 'package:road_helperr/ui/screens/otp_expired_screen.dart';
import 'package:road_helperr/utils/app_colors.dart';

class OtpScreen extends StatefulWidget {
  static const String routeName = "otpscreen";

  const OtpScreen({super.key});

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final Map<String, TextEditingController> controllers = {
    'N1': TextEditingController(),
    'N2': TextEditingController(),
    'N3': TextEditingController(),
    'N4': TextEditingController(),
    'N5': TextEditingController(),
    'N6': TextEditingController(),
  };

  final Map<String, FocusNode> focusNodes = {
    'F1': FocusNode(),
    'F2': FocusNode(),
    'F3': FocusNode(),
    'F4': FocusNode(),
    'F5': FocusNode(),
    'F6': FocusNode(),
  };

  int _remainingTime = 60;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() => _remainingTime--);
      } else {
        _timer.cancel();
        _navigateToTimeoutScreen();
      }
    });
  }

  void nextField({required String value, required FocusNode? nextFocus}) {
    if (value.isNotEmpty && nextFocus != null) {
      nextFocus.requestFocus();
    }
  }

  void _navigateToTimeoutScreen() {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const OtpExpiredScreen()),
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    for (var controller in controllers.values) {
      controller.dispose();
    }
    for (var focusNode in focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ديناميك مع الثيم
    final bgColor = AppColors.getBackgroundColor(context);
    final containerColor = AppColors.getCardColor(context);
    final textColor = AppColors.getTextStackColor(context);
    final buttonColor = AppColors.getSignAndRegister(context);

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  _buildTopImage(),
                  _buildMainContainer(
                      context, containerColor, textColor, buttonColor),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopImage() {
    return Center(
      child: Image.asset(
        "assets/images/chracters.png",
        width: MediaQuery.of(context).size.width * 0.4,
        height: MediaQuery.of(context).size.height * 0.2,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildMainContainer(BuildContext context, Color containerColor,
      Color textColor, Color buttonColor) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.75,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.6,
        maxWidth: MediaQuery.of(context).size.width * 0.9,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05,
        vertical: MediaQuery.of(context).size.height * 0.02,
      ),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildVerificationText(textColor),
          SizedBox(height: MediaQuery.of(context).size.height * 0.04),
          _buildOtpFields(),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          _buildTimer(textColor),
          SizedBox(height: MediaQuery.of(context).size.height * 0.04),
          _buildButtons(buttonColor),
        ],
      ),
    );
  }

  Widget _buildVerificationText(Color textColor) {
    return Text(
      "We have sent a verification\ncode to the email\n\"A**@gmail.com\"",
      style: TextStyle(
        fontSize: MediaQuery.of(context).size.width * 0.04,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildOtpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: _buildSingleOtpField(
            controllers['N${index + 1}']!,
            focusNodes['F${index + 1}']!,
            index < 5 ? focusNodes['F${index + 2}'] : null,
          ),
        );
      }),
    );
  }

  Widget _buildSingleOtpField(TextEditingController controller,
      FocusNode currentFocus, FocusNode? nextFocus) {
    final containerColor = AppColors.getCardColor(context);

    return SizedBox(
      width: 40,
      height: 50,
      child: TextField(
        controller: controller,
        focusNode: currentFocus,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: containerColor,
          border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8))),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            nextField(value: value, nextFocus: nextFocus);
          }
        },
      ),
    );
  }

  Widget _buildTimer(Color textColor) {
    return Text(
      "00:${_remainingTime.toString().padLeft(2, '0')}",
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  Widget _buildButtons(Color buttonColor) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: () {
        bool isOtpComplete = controllers.values
            .every((controller) => controller.text.isNotEmpty);

        if (isOtpComplete) {
          _timer.cancel();
          Navigator.pushNamed(context, HomeScreen.routeName);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("All fields must be filled out ",
                  textAlign: TextAlign.center),
              backgroundColor: Colors.grey,
            ),
          );
        }
      },
      child: const Text(
        "Verify",
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }
}







// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:road_helperr/ui/screens/bottomnavigationbar_screes/home_screen.dart';
// import 'package:road_helperr/ui/screens/otp_expired_screen.dart';
//
//
// class OtpScreen extends StatefulWidget {
//   static const String routeName = "otpscreen";
//
//   const OtpScreen({super.key});
//
//   @override
//   _OtpScreenState createState() => _OtpScreenState();
// }
//
// class _OtpScreenState extends State<OtpScreen> {
//   final Map<String, TextEditingController> controllers = {
//     'N1': TextEditingController(),
//     'N2': TextEditingController(),
//     'N3': TextEditingController(),
//     'N4': TextEditingController(),
//     'N5': TextEditingController(),
//     'N6': TextEditingController(),
//   };
//
//   final Map<String, FocusNode> focusNodes = {
//     'F1': FocusNode(),
//     'F2': FocusNode(),
//     'F3': FocusNode(),
//     'F4': FocusNode(),
//     'F5': FocusNode(),
//     'F6': FocusNode(),
//   };
//
//   int _remainingTime = 60; // التايمر مدته 60 ثانية
//   late Timer _timer;
//
//   @override
//   void initState() {
//     super.initState();
//     _startTimer(); // بدء التايمر عند فتح الشاشة
//   }
//
//   void _startTimer() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_remainingTime > 0) {
//         setState(() {
//           _remainingTime--;
//         });
//       } else {
//         _timer.cancel(); // إيقاف التايمر عند انتهاء الوقت
//         _navigateToTimeoutScreen(); // الانتقال إلى شاشة الوقت المنتهي
//       }
//     });
//   }
//
//   void nextField({required String value, required FocusNode? nextFocus}) {
//     if (value.isNotEmpty && nextFocus != null) {
//       nextFocus.requestFocus();
//     }
//   }
//
//   void _checkOtpAndNavigate(BuildContext context) {
//     // التحقق من اكتمال جميع الخانات
//     bool isOtpComplete = controllers.values.every((controller) => controller.text.isNotEmpty);
//
//     if (isOtpComplete) {
//       // الانتقال إلى الشاشة التالية
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => const HomeScreen()),
//       );
//     }
//   }
//
//   void _navigateToTimeoutScreen() {
//     // الانتقال إلى شاشة الوقت المنتهي
//     if (mounted) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => const OtpExpiredScreen()),
//       );
//     }
//   }
//
//   @override
//   void dispose() {
//     _timer.cancel(); // إيقاف التايمر عند تدمير الشاشة
//     for (var controller in controllers.values) {
//       controller.dispose();
//     }
//     for (var focusNode in focusNodes.values) {
//       focusNode.dispose();
//     }
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.backgroundColor,
//       resizeToAvoidBottomInset: false,
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           return SingleChildScrollView(
//             physics: const BouncingScrollPhysics(),
//             child: Padding(
//               padding: EdgeInsets.only(
//                 bottom: MediaQuery.of(context).viewInsets.bottom,
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   SizedBox(height: MediaQuery.of(context).size.height * 0.05),
//                   _buildTopImage(),
//                   _buildMainContainer(context),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildTopImage() {
//     return Center(
//       child: Image.asset(
//         "assets/images/chracters.png", // تأكد من وجود الصورة في المسار الصحيح
//         width: MediaQuery.of(context).size.width * 0.4,
//         height: MediaQuery.of(context).size.height * 0.2,
//         fit: BoxFit.contain,
//       ),
//     );
//   }
//
//   Widget _buildMainContainer(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       height: MediaQuery.of(context).size.height * 0.75,
//       constraints: BoxConstraints(
//         minHeight: MediaQuery.of(context).size.height * 0.6,
//         maxWidth: MediaQuery.of(context).size.width * 0.9,
//       ),
//       padding: EdgeInsets.symmetric(
//         horizontal: MediaQuery.of(context).size.width * 0.05,
//         vertical: MediaQuery.of(context).size.height * 0.02,
//       ),
//       decoration: const BoxDecoration(
//         color: AppColors.containerColor,
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(20),
//           topRight: Radius.circular(20),
//         ),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           _buildVerificationText(),
//           SizedBox(height: MediaQuery.of(context).size.height * 0.04),
//           _buildOtpFields(),
//           SizedBox(height: MediaQuery.of(context).size.height * 0.02),
//           _buildTimer(),
//           SizedBox(height: MediaQuery.of(context).size.height * 0.02),
//           _buildWarningMessage(),
//           SizedBox(height: MediaQuery.of(context).size.height * 0.04),
//           _buildButtons(),
//           SizedBox(height: MediaQuery.of(context).size.height * 0.03),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildVerificationText() {
//     return Text(
//       "We have sent a verification\ncode to the email\n\"A******@gmail.com\"",
//       style: TextStyle(
//         fontSize: MediaQuery.of(context).size.width * 0.04,
//         fontWeight: FontWeight.w500,
//         color: AppColors.textColor,
//       ),
//       textAlign: TextAlign.center,
//     );
//   }
//
//   Widget _buildOtpFields() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         _buildSingleOtpField(controllers['N1']!, focusNodes['F1']!, focusNodes['F2']),
//         SizedBox(width: MediaQuery.of(context).size.width * 0.02),
//         _buildSingleOtpField(controllers['N2']!, focusNodes['F2']!, focusNodes['F3']),
//         SizedBox(width: MediaQuery.of(context).size.width * 0.02),
//         _buildSingleOtpField(controllers['N3']!, focusNodes['F3']!, focusNodes['F4']),
//         SizedBox(width: MediaQuery.of(context).size.width * 0.02),
//         _buildSingleOtpField(controllers['N4']!, focusNodes['F4']!, focusNodes['F5']),
//         SizedBox(width: MediaQuery.of(context).size.width * 0.02),
//         _buildSingleOtpField(controllers['N5']!, focusNodes['F5']!, focusNodes['F6']),
//         SizedBox(width: MediaQuery.of(context).size.width * 0.02),
//         _buildSingleOtpField(controllers['N6']!, focusNodes['F6']!, null),
//       ],
//     );
//   }
//
//   Widget _buildSingleOtpField(
//       TextEditingController controller,
//       FocusNode currentFocus,
//       FocusNode? nextFocus,
//       ) {
//     return SizedBox(
//       width: MediaQuery.of(context).size.width * 0.13,
//       height: MediaQuery.of(context).size.height * 0.06,
//       child: TextField(
//         controller: controller,
//         focusNode: currentFocus,
//         textAlign: TextAlign.center,
//         keyboardType: TextInputType.number,
//         maxLength: 1,
//         style: const TextStyle(color: Colors.black), // لون النص داخل المربع أسود
//         decoration: InputDecoration(
//           counterText: '',
//           filled: true,
//           fillColor: Colors.white, // لون خلفية المربع أبيض
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: BorderSide.none,
//           ),
//         ),
//         onChanged: (value) {
//           if (value.isNotEmpty) {
//             nextField(value: value, nextFocus: nextFocus);
//           }
//           // التحقق من اكتمال OTP والانتقال إلى الشاشة التالية
//           _checkOtpAndNavigate(context);
//         },
//       ),
//     );
//   }
//
//   Widget _buildTimer() {
//     return Text(
//       "00:${_remainingTime.toString().padLeft(2, '0')}", // عرض التايمر بتنسيق 00:00
//       style: TextStyle(
//         fontSize: MediaQuery.of(context).size.width * 0.05,
//         fontWeight: FontWeight.w500,
//         color: AppColors.textColor,
//       ),
//     );
//   }
//
//   Widget _buildWarningMessage() {
//     return Padding(
//       padding: EdgeInsets.symmetric(
//         horizontal: MediaQuery.of(context).size.width * 0.05,
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.warning, color: Colors.yellow, size: MediaQuery.of(context).size.width * 0.06),
//           SizedBox(width: MediaQuery.of(context).size.width * 0.02),
//           Expanded(
//             child: Text(
//               "This is a temporary code, do not share it with anyone. Sharing the OTP with others can lead to significant security risks. The OTP is intended to be a private code.",
//               style: TextStyle(
//                 fontSize: MediaQuery.of(context).size.width * 0.03,
//                 fontWeight: FontWeight.w400,
//                 color: AppColors.textColor,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),
//
//         ],
//       ),
//     );
//
//   }
//
//   Widget _buildButtons() {
//     return Padding(
//       padding: EdgeInsets.symmetric(
//         horizontal: MediaQuery.of(context).size.width * 0.05,
//       ),
//       child: Column(
//         children: [
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppColors.primaryButtonColor,
//               minimumSize: Size(double.infinity, MediaQuery.of(context).size.height * 0.07),
//             ),
//             onPressed: () {
//                   () {
//                 Navigator.of(context)
//                     .pushNamed(HomeScreen.routeName);
//               };
//             },
//             child: Text(
//               "Verify",
//               style: TextStyle(
//                 fontSize: MediaQuery.of(context).size.width * 0.04,
//                 fontWeight: FontWeight.w700,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//           SizedBox(height: MediaQuery.of(context).size.height * 0.02),
//         ],
//       ),
//     );
//   }
// }
//
// class NextScreen extends StatelessWidget {
//   const NextScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Text(
//           "تم التحقق بنجاح!",
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//             color: Colors.black,
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class TimeoutScreen extends StatelessWidget {
//   const TimeoutScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.red[100],
//       body: Center(
//         child: Text(
//           "انتهى الوقت! لم يتم إدخال OTP بالكامل.",
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//             color: Colors.red[900],
//           ),
//           textAlign: TextAlign.center,
//         ),
//       ),
//     );
//   }
// }
//
// class AppColors {
//   static const Color backgroundColor = Color(0xFF1F3551);
//   static const Color containerColor = Color(0xFF01122A);
//   static const Color textColor = Color(0xFFA4A4A4);
//   static const Color primaryButtonColor = Color(0xFF023A87);
//   static const Color secondaryButtonColor = Color(0xFF808080);
// }