import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';
import '../../../auth/data/auth_service.dart';

class DoctorPersonalInfoScreen extends StatefulWidget {
  final UserProfile? user;
  const DoctorPersonalInfoScreen({super.key, this.user});

  @override
  State<DoctorPersonalInfoScreen> createState() => _DoctorPersonalInfoScreenState();
}

class _DoctorPersonalInfoScreenState extends State<DoctorPersonalInfoScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.user?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: widget.user?.lastName ?? '');
    _phoneCtrl = TextEditingController(text: widget.user?.phone ?? '');
    _emailCtrl = TextEditingController(text: widget.user?.email ?? '');
    _addressCtrl = TextEditingController(text: widget.user?.address ?? '');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final payload = {
      'firstName': _firstNameCtrl.text,
      'lastName': _lastNameCtrl.text,
      'phone': _phoneCtrl.text,
      'address': _addressCtrl.text,
    };

    try {
      final result = await _authService.updateMyInfo(widget.user!.id, payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: result['success'] ? Colors.green : Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi cập nhật')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thông tin cá nhân', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('Quản lý thông tin liên hệ và cơ bản của bạn', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            
            Row(
              children: [
                Expanded(child: _buildTextField(_firstNameCtrl, 'Họ', Icons.person_outline)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_lastNameCtrl, 'Tên', Icons.person_outline)),
              ],
            ),
            _buildTextField(_emailCtrl, 'Email', Icons.email_outlined, readOnly: true),
            _buildTextField(_phoneCtrl, 'Số điện thoại', Icons.phone_android_rounded),
            _buildTextField(_addressCtrl, 'Địa chỉ hiện tại', Icons.location_on_outlined, maxLines: 2),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38A3A5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('LƯU THAY ĐỔI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {bool readOnly = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl,
            readOnly: readOnly,
            maxLines: maxLines,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF38A3A5), size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38A3A5), width: 2)),
              filled: true,
              fillColor: readOnly ? Colors.grey[100] : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập thông tin' : null,
          ),
        ],
      ),
    );
  }
}
