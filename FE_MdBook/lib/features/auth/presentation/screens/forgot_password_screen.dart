import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _isSent = false;
  bool _loading = false;

  void _handleSend() async {
    if (_emailCtrl.text.isEmpty) return;
    
    setState(() => _loading = true);
    // Mocking an API call
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _loading = false;
      _isSent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isSent ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quên mật khẩu?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
        const SizedBox(height: 12),
        const Text(
          'Đừng lo lắng! Vui lòng nhập email liên kết với tài khoản của bạn. Chúng tôi sẽ gửi mã đặt lại mật khẩu cho bạn.',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
          child: TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'Nhập email của bạn', border: InputBorder.none, icon: Icon(Icons.email_outlined, color: Color(0xFF38A3A5))),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _loading ? null : _handleSend,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38A3A5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: _loading 
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('GỬI MÃ XÁC NHẬN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF38A3A5).withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.mark_email_read_rounded, size: 80, color: Color(0xFF38A3A5)),
          ),
          const SizedBox(height: 24),
          const Text('Đã gửi email!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            'Chúng tôi đã gửi mã xác nhận đến ${_emailCtrl.text}. Vui lòng kiểm tra hộp thư của bạn.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 48),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('QUAY LẠI ĐĂNG NHẬP', style: TextStyle(color: Color(0xFF38A3A5), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
