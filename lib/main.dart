import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'state/prayer_controller.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dark navigation bar and status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: MinarTheme.midnightBottom,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize offline storage & local notifications
  final storage = await StorageService.init();
  try {
    final notifications = NotificationService();
    await notifications.init();
  } catch (e) {
    debugPrint('Notifications init note: $e');
  }

  final controller = PrayerController(storage);

  runApp(MinarApp(controller: controller));
}

class MinarApp extends StatelessWidget {
  final PrayerController controller;

  const MinarApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'Minar',
          debugShowCheckedModeBanner: false,
          theme: MinarTheme.darkTheme(controller.fontFamily),
          home: HomeScreen(controller: controller),
        );
      },
    );
  }
}
