import 'package:flutter/material.dart';
import 'package:tbdd/features/auth/data/auth_service.dart';
import 'package:tbdd/features/user/screens/user_profile_edit_screen.dart';
import 'package:tbdd/core/models/user_model.dart';

class PatientMedicalRecordScreen extends StatefulWidget {
  const PatientMedicalRecordScreen({super.key});

  @override
  State<PatientMedicalRecordScreen> createState() => _PatientMedicalRecordScreenState();
}

class _PatientMedicalRecordScreenState extends State<PatientMedicalRecordScreen> {
  final AuthService _authService = AuthService();
  UserProfile? _user;
  bool _loading = true;
  bool _isGeneratingAi = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _authService.getMyInfo();
      if (mounted) {
        setState(() {
          _user = user;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generateAiSummary() async {
    setState(() => _isGeneratingAi = true);
    final result = await _authService.generateAiSummary();
    if (mounted) {
      setState(() => _isGeneratingAi = false);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật tóm tắt thông minh'), backgroundColor: Colors.green));
        _loadUser();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${result['message']}'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_user == null) return const Scaffold(body: Center(child: Text('Không tìm thấy thông tin')));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Hồ sơ y tế của tôi', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserProfileEditScreen(user: _user!)),
              );
              if (result == true) _loadUser();
            },
            icon: const Icon(Icons.edit_note, color: Color(0xFF38A3A5)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(),
            const SizedBox(height: 24),
            _buildMedicalStats(),
            const SizedBox(height: 24),
            _buildSection('Tiền sử bệnh lý', _user!.medicalHistory ?? 'Chưa có thông tin', Icons.history),
            const SizedBox(height: 16),
            _buildSection('Dị ứng', _user!.allergies ?? 'Chưa có thông tin', Icons.warning_amber_rounded),
            const SizedBox(height: 24),
            const SizedBox(height: 24),
            _buildAiSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: const Color(0xFF38A3A5).withOpacity(0.1),
            child: const Icon(Icons.person, size: 40, color: Color(0xFF38A3A5)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_user!.firstName ?? ''} ${_user!.lastName ?? ''}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_user!.email, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalStats() {
    return Row(
      children: [
        Expanded(child: _buildStatItem('Cân nặng', '${_user!.weight ?? "--"} kg', Icons.monitor_weight_outlined)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatItem('Chiều cao', '${_user!.height ?? "--"} cm', Icons.height)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatItem('Nhóm máu', _user!.bloodType ?? "--", Icons.bloodtype_outlined)),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF38A3A5), size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF38A3A5), size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(color: Colors.black87, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildAiSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _user!.aiSummary != null ? [Colors.blue[400]!, Colors.blue[600]!] : [Colors.grey[400]!, Colors.grey[600]!]
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Tóm tắt y tế thông minh (AI)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              if (_isGeneratingAi)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              else
                IconButton(
                  onPressed: _generateAiSummary,
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                  tooltip: 'Tạo lại tóm tắt',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_user!.aiSummary ?? 'Nhấn nút làm mới để tạo tóm tắt thông minh từ tiền sử bệnh và dị ứng của bạn.',
              style: const TextStyle(color: Colors.white, height: 1.5, fontSize: 14)),
        ],
      ),
    );
  }
}
