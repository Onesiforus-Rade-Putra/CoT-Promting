import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/api_config.dart';
import 'services/auth_service.dart';
import 'services/progress_tracking_service.dart';
import 'services/quiz_service.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/progress_tracking_view_model.dart';
import 'viewmodels/quiz_view_model.dart';
import 'viewmodels/register_viewmodel.dart';
import 'views/dashboard_page.dart';
import 'views/login_page.dart';
import 'views/quiz_list_page.dart';
import 'views/reset_password_page.dart';
import 'views/signup_page.dart';
import 'views/supporting_feature_pages.dart';
import 'views/target_task_page.dart';

void main() {
  runApp(const MahasiswaSuksesApp());
}

class MahasiswaSuksesApp extends StatelessWidget {
  const MahasiswaSuksesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<ProgressTrackingService>(
          create: (_) => ProgressTrackingService(
            baseUrl: ApiConfig.baseUrl,
          ),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<QuizService>(
          create: (_) => QuizService(),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            authService: context.read<AuthService>(),
          ),
        ),
        ChangeNotifierProvider<RegisterViewModel>(
          create: (context) => RegisterViewModel(
            context.read<AuthService>(),
          ),
        ),
        ChangeNotifierProvider<ProgressTrackingViewModel>(
          create: (context) => ProgressTrackingViewModel(
            context.read<ProgressTrackingService>(),
          ),
        ),
        ChangeNotifierProvider<QuizViewModel>(
          create: (context) => QuizViewModel(
            quizService: context.read<QuizService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Mahasiswa Sukses',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD71920),
            primary: const Color(0xFFD71920),
          ),
          scaffoldBackgroundColor: Colors.white,
          inputDecorationTheme: const InputDecorationTheme(
            floatingLabelBehavior: FloatingLabelBehavior.never,
          ),
        ),
        initialRoute: LoginPage.routeName,
        routes: <String, WidgetBuilder>{
          LoginPage.routeName: (_) => const LoginPage(),
          DashboardPage.routeName: (_) => const DashboardPage(),
          ResetPasswordPage.routeName: (_) => const ResetPasswordPage(),
          RegisterView.routeName: (_) => const RegisterView(),
          DashboardRoutes.profile: (_) => const ProfilePage(),
          DashboardRoutes.quizList: (_) => const QuizListPage(),
          DashboardRoutes.targetTasks: (_) => const TargetTaskPage(),
          DashboardRoutes.forum: (_) => const ForumPage(),
          DashboardRoutes.achievements: (_) => const AchievementPage(),
          DashboardRoutes.quests: (_) => const QuestPage(),
          DashboardRoutes.leaderboard: (_) => const LeaderboardPage(),
          DashboardRoutes.settings: (_) => const SettingsPage(),
        },
      ),
    );
  }
}
