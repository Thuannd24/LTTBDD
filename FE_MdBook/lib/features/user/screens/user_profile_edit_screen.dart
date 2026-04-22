import 'package:flutter/material.dart';
import 'package:tbdd/features/auth/data/auth_service.dart';
import 'package:tbdd/core/models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UserProfileEditScreen extends StatefulWidget {
  final UserProfile user;
  final bool isSelf;
  const UserProfileEditScreen({super.key, required this.user, this.isSelf = false});

  @override
  State<UserProfileEditScreen> createState() => _UserProfileEditScreenState();
}

class _UserProfileEditScreenState extends State<UserProfileEditScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _bloodTypeCtrl;
  late TextEditingController _medicalHistoryCtrl;
  late TextEditingController _allergiesCtrl;

  bool _isSaving = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isMe = false;

  @override
  void initState() {
    super.initState();
    _isMe = widget.isSelf;
    _firstNameCtrl = TextEditingController(text: widget.user.firstName);
    _lastNameCtrl = TextEditingController(text: widget.user.lastName);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
    _addressCtrl = TextEditingController(text: widget.user.address);
    _weightCtrl = TextEditingController(text: widget.user.weight?.toString() ?? '');
    _heightCtrl = TextEditingController(text: widget.user.height?.toString() ?? '');
    _bloodTypeCtrl = TextEditingController(text: widget.user.bloodType ?? '');
    _medicalHistoryCtrl = TextEditingController(text: widget.user.medicalHistory ?? '');
    _allergiesCtrl = TextEditingController(text: widget.user.allergies ?? '');
    if (!_isMe) {
      _checkIsMe();
    }
  }

  Future<void> _checkIsMe() async {
    final me = await _authService.getMyInfo();
    if (mounted && me != null) {
      setState(() {
        _isMe = me.userId == widget.user.userId;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
      // Optionally upload immediately or wait for save
      _uploadAvatar(image.path);
    }
  }
  
  Future<void> _uploadAvatar(String path) async {
    final result = await _authService.updateAvatar(path);
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: result['success'] ? Colors.green : Colors.red),
       );
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final payload = {
        'firstName': _firstNameCtrl.text,
        'lastName': _lastNameCtrl.text,
        'phone': _phoneCtrl.text,
        'address': _addressCtrl.text,
        'weight': double.tryParse(_weightCtrl.text),
        'height': double.tryParse(_heightCtrl.text),
        'bloodType': _bloodTypeCtrl.text,
        'medicalHistory': _medicalHistoryCtrl.text,
        'allergies': _allergiesCtrl.text,
      };

      // If it's me, use updateMyInfo, otherwise (Doctor/Admin) use updateUserInfo
      final result = _isMe 
          ? await _authService.updateMyInfo(widget.user.userId, payload)
          : await _authService.updateUserInfo(widget.user.userId, payload);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật thành công'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception(result['message']);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cập nhật thông tin'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: CircularProgressIndicator(strokeWidth: 2)))
          else
            IconButton(onPressed: _save, icon: const Icon(Icons.check, color: Color(0xFF38A3A5))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _imageFile != null 
                        ? FileImage(_imageFile!) 
                        : (widget.user.avatar != null ? NetworkImage(widget.user.avatar!) : null) as ImageProvider?,
                      child: widget.user.avatar == null && _imageFile == null 
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
              const SizedBox(height: 32),
              _buildTextField('Họ', _firstNameCtrl),
              const SizedBox(height: 16),
              _buildTextField('Tên', _lastNameCtrl),
              const SizedBox(height: 16),
              _buildTextField('Số điện thoại', _phoneCtrl, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField('Địa chỉ', _addressCtrl, maxLines: 2),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField('Cân nặng (kg)', _weightCtrl, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Chiều cao (cm)', _heightCtrl, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('Nhóm máu', _bloodTypeCtrl),
              const SizedBox(height: 16),
              const Divider(),
              const Text('Thông tin sức khỏe', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildTextField('Tiền sử bệnh lý', _medicalHistoryCtrl, maxLines: 3),
              const SizedBox(height: 16),
              _buildTextField('Dị ứng', _allergiesCtrl, maxLines: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập $label' : null,
    );
  }
}
