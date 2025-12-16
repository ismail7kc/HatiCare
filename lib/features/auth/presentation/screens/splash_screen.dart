import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/auth/presentation/screens/login_screen.dart';
import 'package:haticare/features/auth/presentation/viewmodels/login_view_model.dart';
import 'package:haticare/features/doctor/presentation/screens/doctor_home_screen.dart';
import 'package:haticare/features/doctor/presentation/screens/doctor_verfications/doctor_verification.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_home_screen.dart';
import 'package:haticare/features/pharmacy/presentation/screens/edit_pharmacy_profile_screen.dart';
import 'package:haticare/features/laboratory/presentation/screens/laboratory_home_screen.dart';
import 'package:haticare/features/laboratory/presentation/screens/edit_laboratory_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // Disable keyboard on splash screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();

    _checkLoginStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(milliseconds: 5000));

    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final accessToken = prefs.getString('access_token');
      final userType = prefs.getString('user_type');

      if (isLoggedIn && accessToken != null && accessToken.isNotEmpty) {
        if (userType == 'doctor') {
          // final prefs = await SharedPreferences.getInstance();
          // final bool isProfileCompleted = prefs.getBool(CacheKeys.isProfileCompleted) ?? false;

          // if (isProfileCompleted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => DoctorHomeScreen()),
            );
          // } 
          // else {
          //   Navigator.of(context).pushReplacement(
          //     MaterialPageRoute(builder: (_) => DoctorVerificationScreen()),
          //   );
          // }
        } else if (userType == 'pharmacy') {
          // PHARMACY: Check if profile is completed
          final profileCompleted = prefs.getBool('pharmacy_profile_completed') ?? false;
          final pharmacyId = prefs.getString('pharmacy_id') ?? '';
          
          if (!profileCompleted) {
            // Force profile completion if incomplete
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => EditPharmacyProfileScreen(
                  pharmacyId: pharmacyId,
                  isForceComplete: true,
                ),
              ),
            );
          } else {
            // Profile completed, allow home screen access
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const PharmacyHomeScreen()),
            );
          }
        } else if (userType == 'laboratory') {
          // LABORATORY: Check if profile is completed
          final profileCompleted = prefs.getBool('laboratory_profile_completed') ?? false;
          final laboratoryId = prefs.getString('laboratory_id') ?? '';
          
          if (!profileCompleted) {
            // Force profile completion if incomplete
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => EditLaboratoryProfileScreen(
                  laboratoryId: laboratoryId,
                  isForceComplete: true,
                  openedFromSettings: false,
                ),
              ),
            );
          } else {
            // Profile completed, allow home screen access
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LaboratoryHomeScreen()),
            );
          }
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error checking login status: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard if it appears
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            if (_animationController.value == 0.0) {
              return const SizedBox.shrink();
            }
            return Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/haticare_logo.png',
                          width: 150,
                          height: 150,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'HatiCare',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
