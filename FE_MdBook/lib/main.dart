import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tbdd/features/auth/presentation/screens/login_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Lắng nghe notification khi app bị tắt
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);
  
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Yêu cầu quyền nhận thông báo (iOS requires this, Android 13+ requires this)
    await FirebaseMessaging.instance.requestPermission();
    
    // In token ra console để test độc lập không cần Backend tải
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint("======== MÃ FCM TOKEN CỦA BẠN ========");
    debugPrint(token);
    debugPrint("======================================");
  } catch (e) {
    debugPrint("Lỗi khởi tạo Firebase. Vui lòng cấu hình google-services.json: $e");
  }

  try {
    // Tải file .env
    await dotenv.load(fileName: ".env");
    debugPrint("✅ Đã tải file .env thành công!");
    debugPrint("API URL: ${dotenv.env['API_URL']}");
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
