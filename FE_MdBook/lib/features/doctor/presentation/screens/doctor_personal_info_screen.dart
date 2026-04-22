import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';
import '../../../auth/data/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _bloodTypeCtrl;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _bloodTypeCtrl = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final user = await _authService.getMyInfo();
    if (mounted && user != null) {
      setState(() {
        _firstNameCtrl.text = user.firstName ?? '';
        _lastNameCtrl.text = user.lastName ?? '';
        _phoneCtrl.text = user.phone ?? '';
        _emailCtrl.text = user.email ?? '';
        _addressCtrl.text = user.address ?? '';
        _bloodTypeCtrl.text = user.bloodType ?? '';
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
      final result = await _authService.updateAvatar(image.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: result['success'] ? Colors.green : Colors.red),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final payload = {
      'firstName': _firstNameCtrl.text,
      'lastName': _lastNameCtrl.text,
      'phone': _phoneCtrl.text,
      'address': _addressCtrl.text,
      'bloodType': _bloodTypeCtrl.text,
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
      if (mounted) {
        setState(() => _isLoading = false);
        _loadProfile(); // Refresh after save
      }
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
            const SizedBox(height: 24),
            
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _imageFile != null 
                        ? FileImage(_imageFile!) 
                        : (widget.user?.avatar != null ? NetworkImage(widget.user!.avatar!) : null) as ImageProvider?,
                      child: widget.user?.avatar == null && _imageFile == null 
                        ? const Icon(Icons.camera_alt, size: 30, color: Colors.grey) 
                        : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Color(0xFF38A3A5), shape: BoxShape.circle),
                        child: const Icon(Icons.edit, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
            _buildTextField(_bloodTypeCtrl, 'Nhóm máu', Icons.water_drop_outlined),
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
