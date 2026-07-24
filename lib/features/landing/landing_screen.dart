import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/features/auth/login_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    // _OnboardingData(
    //   title: 'Turn Old Devices\ninto Cash',
    //   subtitle:
    //       'Join 50,000+ users who have sold their e-waste responsibly. Get instant AI pricing for your devices.',
    //   icon: Icons.recycling_rounded,
    //   tag: 'Eco-Friendly',
    //   primaryColor: AppColors.primary,
    //   cardColor: const Color(0xFFD1FAE5),
    // ),
    // _OnboardingData(
    //   title: 'Smart AI\nPricing Engine',
    //   subtitle:
    //       'Our advanced AI analyzes your device photos to determine accurate pricing in seconds — no manual input needed.',
    //   icon: Icons.auto_awesome_rounded,
    //   tag: 'AI-Powered',
    //   primaryColor: const Color(0xFF0F766E), // Teal
    //   cardColor: const Color(0xFFCCFBF1),
    // ),
    // _OnboardingData(
    //   title: 'Make a Real\nImpact Today',
    //   subtitle:
    //       '2.4M kg of e-waste diverted from landfills. Sell your devices and earn verified green certificates.',
    //   icon: Icons.eco_rounded,
    //   tag: 'Sustainable',
    //   primaryColor: const Color(0xFF65A30D),
    //   cardColor: const Color(0xFFECFCCB),
    // ),
    // _OnboardingData(
    //   title: 'Free Doorstep\nPickup',
    //   subtitle:
    //       'Schedule a time that works for you. Our executives will pick up the device and pay you instantly on the spot.',
    //   icon: Icons.local_shipping_rounded,
    //   tag: 'Convenient',
    //   primaryColor: const Color(0xFFF59E0B),
    //   cardColor: const Color(0xFFFEF3C7),
    // ),
    _OnboardingData(
      title: 'Turn Old Devices\ninto Cash',
      subtitle:
          'Your e-waste is collected, recycled, and turned into cash.',
      icon: Icons.autorenew_rounded,
      tag: 'E-waste',
      primaryColor: const Color(0xFF0F766E),
      cardColor: const Color(0xFFCCFBF1),
      isAnimation: true,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToMain();
    }
  }

  void _goToMain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _OnboardingPage(data: _pages[index]);
            },
          ),

          // Top Bar (Logo & Skip)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.recycling_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ReCircle',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: _goToMain,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(
                      height: 48,
                    ), // Match button height for alignment
                ],
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xxxl,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.white,
                    Colors.white.withValues(alpha: 0.9),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                  stops: const [0.6, 0.85, 1.0],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page Indicators
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: List.generate(
                  //     _pages.length,
                  //     (index) => AnimatedContainer(
                  //       duration: const Duration(milliseconds: 300),
                  //       margin: const EdgeInsets.symmetric(horizontal: 4),
                  //       width: _currentPage == index ? 28 : 8,
                  //       height: 8,
                  //       decoration: BoxDecoration(
                  //         color: _currentPage == index
                  //             ? AppColors.primary
                  //             : AppColors.border,
                  //         borderRadius: BorderRadius.circular(4),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      if (_currentPage == _pages.length - 1)
                        // Expanded(
                        //   child: OutlinedButton(
                        //     onPressed: _goToLogin,
                        //     style: OutlinedButton.styleFrom(
                        //       side: const BorderSide(
                        //         color: AppColors.border,
                        //         width: 2,
                        //       ),
                        //       padding: const EdgeInsets.symmetric(vertical: 16),
                        //       shape: RoundedRectangleBorder(
                        //         borderRadius: BorderRadius.circular(16),
                        //       ),
                        //     ),
                        //     child: const Text(
                        //       'Log In',
                        //       style: TextStyle(
                        //         color: AppColors.textPrimary,
                        //         fontSize: 16,
                        //         fontWeight:  FontWeight.w700,
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      if (_currentPage == _pages.length - 1)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: AppColors.primary.withValues(alpha: 0.4),
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? 'Lets Get Started'
                                : 'Next',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String subtitle;
  final IconData icon;
  final String tag;
  final Color primaryColor;
  final Color cardColor;
  final bool isAnimation;

  _OnboardingData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tag,
    required this.primaryColor,
    required this.cardColor,
    this.isAnimation = false,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 3),
          if (data.isAnimation)
            const Center(child: RecyclingVideo(key: ValueKey('recycling-video')))
          else
            // Rich Illustration / Icon Display
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: data.cardColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: data.primaryColor.withValues(alpha: 0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(data.icon, size: 64, color: data.primaryColor),
                  ),
                ),
              ),
            ),

          const Spacer(flex: 2),

          // Badge / Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: data.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              data.tag.toUpperCase(),
              style: TextStyle(
                color: data.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.15,
              letterSpacing: -1.2,
            ),
          ),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            data.subtitle,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),

          const Spacer(flex: 3), // Ensure room for bottom controls
        ],
      ),
    );
  }
}

class LiveRecyclingAnimation extends StatefulWidget {
  const LiveRecyclingAnimation({super.key});

  @override
  State<LiveRecyclingAnimation> createState() => _LiveRecyclingAnimationState();
}

class _LiveRecyclingAnimationState extends State<LiveRecyclingAnimation> {
  int _phase = 0;
  Timer? _timer;

  final List<String> _phaseTexts = [
    'E-Waste Collection',
    'Waste Transition',
    'Into the Bin',
    'Recycling',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      if (mounted) {
        setState(() {
          _phase = (_phase + 1) % 4;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double pX = _phase == 0
        ? 40
        : _phase == 1
        ? 80
        : 130;
    double pY = _phase == 0
        ? 80
        : _phase == 1
        ? 110
        : 130;
    double pS = _phase >= 2 ? 0.0 : 1.0;

    double lX = _phase == 0
        ? 100
        : _phase == 1
        ? 110
        : 130;
    double lY = _phase == 0
        ? 110
        : _phase == 1
        ? 120
        : 130;
    double lS = _phase >= 2 ? 0.0 : 1.2;

    double mX = _phase == 0
        ? 170
        : _phase == 1
        ? 140
        : 130;
    double mY = _phase == 0
        ? 130
        : _phase == 1
        ? 130
        : 130;
    double mS = _phase >= 2 ? 0.0 : 1.1;

    double kX = _phase == 0
        ? 230
        : _phase == 1
        ? 170
        : 130;
    double kY = _phase == 0
        ? 160
        : _phase == 1
        ? 140
        : 130;
    double kS = _phase >= 2 ? 0.0 : 0.9;

    double bY = _phase == 0
        ? 200
        : _phase == 1
        ? 170
        : 80;
    double bOp = _phase == 0 ? 0.0 : 1.0;
    double bS = _phase >= 2 ? 1.0 : (_phase == 1 ? 0.8 : 0.5);

    bool showParticles = _phase == 3;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutBack,
                left: 100,
                top: bY,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: bOp,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 1000),
                    scale: bS,
                    child: Container(
                      width: 100,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.primaryDark,
                          width: 4,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                          bottom: Radius.circular(20),
                        ),
                        color: AppColors.primaryLight.withValues(alpha: 0.5),
                        boxShadow: [
                          if (_phase >= 2)
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 500),
                          scale: _phase == 3 ? 1.2 : 0.8,
                          child: Icon(
                            Icons.recycling_rounded,
                            color: _phase == 3
                                ? AppColors.primary
                                : AppColors.primaryDark.withValues(alpha: 0.5),
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              AnimatedPositioned(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutBack,
                left: 90,
                top: bY - 10,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: bOp,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 1000),
                    scale: bS,
                    child: Container(
                      width: 120,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        border: Border.all(
                          color: AppColors.primaryDark,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              _DeviceIcon(
                icon: Icons.smartphone_rounded,
                x: pX,
                y: pY,
                scale: pS,
              ),
              _DeviceIcon(
                icon: Icons.laptop_mac_rounded,
                x: lX,
                y: lY,
                scale: lS,
              ),
              _DeviceIcon(
                icon: Icons.desktop_windows_rounded,
                x: mX,
                y: mY,
                scale: mS,
              ),
              _DeviceIcon(
                icon: Icons.keyboard_rounded,
                x: kX,
                y: kY,
                scale: kS,
              ),

              ...List.generate(8, (index) {
                double angle = index * (pi / 4);
                double dist = showParticles ? 80.0 : 0.0;
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCirc,
                  left: 150 + cos(angle) * dist - 5,
                  top: 140 + sin(angle) * dist - 5,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: showParticles ? 1.0 : 0.0,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 800),
                      scale: showParticles ? 1.0 : 0.0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Text(
            _phaseTexts[_phase],
            key: ValueKey(_phase),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeviceIcon extends StatelessWidget {
  final IconData icon;
  final double x;
  final double y;
  final double scale;

  const _DeviceIcon({
    required this.icon,
    required this.x,
    required this.y,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOutCubic,
      left: x,
      top: y,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 800),
        opacity: scale > 0 ? 1.0 : 0.0,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 1000),
          scale: scale,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blueGrey.shade200, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.blueGrey.shade400, size: 28),
          ),
        ),
      ),
    );
  }
}


class RecyclingVideo extends StatefulWidget {
  const RecyclingVideo({super.key});

  @override
  State<RecyclingVideo> createState() => _RecyclingVideoState();
}

class _RecyclingVideoState extends State<RecyclingVideo> {
  VideoPlayerController? _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset('assets/vdo1.mp4');
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) return;

      await controller.setLooping(true);
      await controller.setVolume(1);
      await controller.play();

      controller.addListener(_onVideoUpdate);
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load video. Run on a real device/emulator '
            'and do a full restart after adding assets.';
      });
      debugPrint('RecyclingVideo init failed: $e');
    }
  }

  void _onVideoUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        color: const Color(0xFFCCFBF1),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off_outlined, size: 48, color: Colors.grey.shade600),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}