import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../data/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateForm() {
    if (_fullnameController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      return AppStrings.fillAllFields;
    }
    if (!_emailController.text.contains('@')) {
      return AppStrings.invalidEmail;
    }
    if (_passwordController.text.length < 6) {
      return AppStrings.passwordTooShort;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      return AppStrings.passwordsDoNotMatch;
    }
    return null;
  }

  void _handleRegister() async {
    final error = _validateForm();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // Simulating BE call or using the placeholder service
    final result = await _authService.register(
      fullname: _fullnameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(AppStrings.registerSuccess),
          content: const Text('Bạn có thể đăng nhập ngay bây giờ'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Đóng dialog
                Navigator.pop(context); // Quay lại LoginScreen
              },
              child: const Text('OK'),
            )
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? AppStrings.registerFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Illustration (Circular like the image)
              Container(
                height: 180,
                width: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: const DecorationImage(
                    image: NetworkImage('https://img.freepik.com/free-vector/happy-family-concept-illustration_114360-1498.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              _buildTextField(
                controller: _fullnameController,
                hint: AppStrings.fullNameHint,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                hint: AppStrings.emailHint,
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                hint: AppStrings.phoneHint,
                icon: Icons.phone_android_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                hint: AppStrings.loginPasswordHint,
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: _obscurePassword,
                onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _confirmPasswordController,
                hint: 'Xác nhận mật khẩu',
                icon: Icons.lock_reset_outlined,
                isPassword: true,
                obscureText: _obscureConfirmPassword,
                onTogglePassword: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38A3A5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        AppStrings.registerButton,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    children: [
                      const TextSpan(text: AppStrings.agreementPart1),
                      TextSpan(
                        text: AppStrings.termsAndPolicy,
                        style: const TextStyle(
                          color: Color(0xFF38A3A5), 
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscureText : false,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: Colors.black87),
          suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                onPressed: onTogglePassword,
              )
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
