import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tbdd/features/auth/presentation/screens/login_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tbdd/core/utils/notification_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);
  
  try {
    // Tải file .env
    await dotenv.load(fileName: ".env");
    debugPrint("✅ Đã tải file .env thành công!");
    debugPrint("API URL: ${dotenv.env['API_URL']}");
    // Khởi tạo Notification Manager
    await NotificationManager.instance.init();
  } catch (e) {
    debugPrint("❌ LỖI TẢI FILE .env: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medical Booking App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF38A3A5),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF38A3A5)),
      ),
      home: const LoginScreen(),
    );
  }
}
