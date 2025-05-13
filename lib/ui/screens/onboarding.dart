import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:road_helperr/services/auth_service.dart';
import 'package:road_helperr/ui/screens/bottomnavigationbar_screes/home_screen.dart';
import 'on_boarding.dart';

class OnboardingScreen extends StatefulWidget {
  static const String routeName = "onvideo";
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late List<VideoPlayerController> _videoControllers;
  late AnimationController _lockAnimationController;
  late Animation<double> _lockAnimation;
  bool _showLock = true;
  bool _showGetStarted = false;
  int _currentVideoIndex = 0;
  bool _isVideoInitialized = false;

  final List<String> videoAssets = [
    'assets/videos/1.mp4',
    'assets/videos/2.mp4',
    'assets/videos/3.mp4',
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('Initializing videos and animations');
    _initializeVideos();
    _initializeLockAnimation();
  }

  Future<void> _initializeVideos() async {
    try {
      debugPrint('Starting video initialization');
      _videoControllers = [];

      for (String asset in videoAssets) {
        debugPrint('Initializing video: $asset');
        final controller = VideoPlayerController.asset(asset);

        await controller.initialize();
        debugPrint('Video initialized: $asset');

        controller.addListener(() {
          if (controller.value.position >= controller.value.duration) {
            debugPrint('Video completed: $asset');
            _onVideoComplete(_videoControllers.indexOf(controller));
          }
        });

        _videoControllers.add(controller);
        debugPrint('Controller added for: $asset');
      }

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          debugPrint('All videos initialized successfully');
        });
      }
    } catch (e) {
      debugPrint('Error initializing videos: $e');
    }
  }

  void _initializeLockAnimation() {
    _lockAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _lockAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _lockAnimationController,
        curve: Curves.easeOut,
      ),
    );
  }

  void _onVideoComplete(int index) {
    if (!mounted) return;
    debugPrint('Processing video completion for index: $index');

    if (index < _videoControllers.length - 1) {
      setState(() {
        _currentVideoIndex = index + 1;
        debugPrint('Playing next video at index: ${index + 1}');
        _videoControllers[_currentVideoIndex].play();
      });
    } else {
      debugPrint('All videos completed, showing get started button');
      setState(() {
        _showGetStarted = true;
      });
    }
  }

  void _onLockTap() {
    debugPrint('Lock tapped');
    _lockAnimationController.forward();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showLock = false;
          // تحقق من أن الفيديو الأول جاهز للتشغيل
          if (_videoControllers.isNotEmpty &&
              _videoControllers[0].value.isInitialized) {
            debugPrint('Starting first video');
            _videoControllers[0].play();
          } else {
            debugPrint('Error: Video controller not ready');
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = MediaQuery.of(context).size;
        final isTablet = constraints.maxWidth > 600;
        final isDesktop = constraints.maxWidth > 1200;

        double lockSize = size.width *
            (isDesktop
                ? 0.08
                : isTablet
                    ? 0.1
                    : 0.15);
        double iconSize = lockSize * 0.4;
        double buttonFontSize = size.width *
            (isDesktop
                ? 0.015
                : isTablet
                    ? 0.02
                    : 0.045);
        double dotSize = size.width *
            (isDesktop
                ? 0.008
                : isTablet
                    ? 0.01
                    : 0.02);

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              if (_isVideoInitialized && _videoControllers.isNotEmpty)
                _buildVideoPlayer(),
              if (_showLock) _buildLockButton(lockSize, iconSize),
              if (!_showLock && !_showGetStarted)
                _buildProgressIndicators(dotSize),
              if (_showGetStarted) _buildGetStartedButton(buttonFontSize, size),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized ||
        _currentVideoIndex >= _videoControllers.length ||
        !_videoControllers[_currentVideoIndex].value.isInitialized) {
      return const Center(
          child: CircularProgressIndicator(
        color: Colors.white,
      ));
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoControllers[_currentVideoIndex].value.aspectRatio,
        child: VideoPlayer(_videoControllers[_currentVideoIndex]),
      ),
    );
  }

  Widget _buildLockButton(double size, double iconSize) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: ScaleTransition(
          scale: _lockAnimation,
          child: GestureDetector(
            onTap: _onLockTap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.lock_outline,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicators(double dotSize) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _videoControllers.length,
            (index) => Container(
              width: dotSize,
              height: dotSize,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentVideoIndex == index
                    ? const Color.fromARGB(255, 13, 51, 83)
                    : Colors.white.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGetStartedButton(double fontSize, Size size) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: SizedBox(
          width: size.width * 0.8,
          child: ElevatedButton(
            onPressed: () {
              debugPrint('Get Started button pressed');
              _navigateToNextScreen();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'Get Started',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // التنقل إلى الشاشة التالية بناءً على حالة تسجيل الدخول
  Future<void> _navigateToNextScreen() async {
    try {
      // التحقق مما إذا كان المستخدم مسجل الدخول
      final authService = AuthService();
      final isLoggedIn = await authService.isLoggedIn();

      debugPrint('=== التنقل إلى الشاشة التالية ===');
      debugPrint('حالة تسجيل الدخول: $isLoggedIn');

      // الحصول على رمز المصادقة للتأكد
      final token = await authService.getToken();
      debugPrint('رمز المصادقة موجود: ${token != null}');
      if (token != null) {
        debugPrint('رمز المصادقة غير فارغ: ${token.isNotEmpty}');
      }
      debugPrint('==============================');

      if (isLoggedIn) {
        // إذا كان المستخدم مسجل الدخول، انتقل مباشرة إلى الشاشة الرئيسية
        if (mounted) {
          debugPrint('المستخدم مسجل الدخول، الانتقال إلى الشاشة الرئيسية');
          Navigator.pushReplacementNamed(context, HomeScreen.routeName);
        }
      } else {
        // إذا لم يكن المستخدم مسجل الدخول، انتقل إلى شاشة تسجيل الدخول
        if (mounted) {
          debugPrint(
              'المستخدم غير مسجل الدخول، الانتقال إلى شاشة تسجيل الدخول');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnBoarding()),
          );
        }
      }
    } catch (e) {
      debugPrint('خطأ في التنقل إلى الشاشة التالية: $e');
      // في حالة حدوث خطأ، انتقل إلى شاشة تسجيل الدخول
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnBoarding()),
        );
      }
    }
  }

  @override
  void dispose() {
    debugPrint('Disposing video controllers');
    for (var controller in _videoControllers) {
      controller.pause();
      controller.dispose();
    }
    _lockAnimationController.dispose();
    super.dispose();
  }
}
