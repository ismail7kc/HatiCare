import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haticare/features/auth/data/services/remote_auth_api_service.dart';
import 'package:haticare/features/auth/presentation/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:haticare/features/auth/domain/repositories/auth_repository.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => RemoteAuthApiService()),
        Provider<AuthRepository>(
          create: (context) =>
              AuthRepositoryImpl(context.read<RemoteAuthApiService>()),
        ),
      ],
      child: MaterialApp(
        title: 'HatiCare',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryDark)
              .copyWith(
                primary: AppColors.primaryDark,
                secondary: AppColors.primaryLight,
                surface: AppColors.surface,
              ),
          primaryColor: AppColors.primaryDark,
          scaffoldBackgroundColor: AppColors.surface,
          useMaterial3: true,
        ),
        navigatorObservers: [ChuckerFlutter.navigatorObserver],
        home: const LoginScreen(),
      ),
    );
  }
}
