import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/auth/presentation/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Tải file .env
    await dotenv.load(fileName: ".env");
    debugPrint("✅ Đã tải file .env thành công!");
    debugPrint("API URL: ${dotenv.env['API_URL']}");
  } catch (e) {
    // Nếu lỗi này hiện ra, nghĩa là bạn chưa khai báo .env trong pubspec.yaml hoặc file nằm sai chỗ
    debugPrint("❌ LỖI TẢI FILE .env: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fashion App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
      ),
      home: const LoginScreen(),
    );
  }
}
