import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tbdd/features/admin/data/specialty_service.dart';
import 'package:tbdd/core/models/specialty_model.dart';

class SpecialtyFormScreen extends StatefulWidget {
  final Specialty? specialty;
  const SpecialtyFormScreen({super.key, this.specialty});

  @override
  State<SpecialtyFormScreen> createState() => _SpecialtyFormScreenState();
}

class _SpecialtyFormScreenState extends State<SpecialtyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final SpecialtyService _service = SpecialtyService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameCtrl;
  late TextEditingController _descriptionCtrl;
  late TextEditingController _overviewCtrl;
  late TextEditingController _servicesCtrl;
  late TextEditingController _technologyCtrl;
  
  String? _imageUrl;
  File? _selectedImage;
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.specialty?.name ?? '');
    _descriptionCtrl = TextEditingController(text: widget.specialty?.description ?? '');
    _overviewCtrl = TextEditingController(text: widget.specialty?.overview ?? '');
    _servicesCtrl = TextEditingController(text: widget.specialty?.services ?? '');
    _technologyCtrl = TextEditingController(text: widget.specialty?.technology ?? '');
    _imageUrl = widget.specialty?.image;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _overviewCtrl.dispose();
    _servicesCtrl.dispose();
    _technologyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _isUploading = true;
      });
      
      try {
        final url = await _service.uploadImage(image.path);
        setState(() {
          _imageUrl = url;
          _isUploading = false;
        });
      } catch (e) {
        setState(() => _isUploading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tải ảnh lên thất bại')));
        }
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    
    final payload = {
      'name': _nameCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
      'overview': _overviewCtrl.text.trim(),
      'services': _servicesCtrl.text.trim(),
      'technology': _technologyCtrl.text.trim(),
      'image': _imageUrl,
    };
    
    try {
      if (widget.specialty == null) {
        await _service.create(payload);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo chuyên khoa thành công')));
      } else {
        await _service.update(widget.specialty!.id, payload);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật chuyên khoa thành công')));
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu thất bại')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.specialty == null ? 'Tạo chuyên khoa' : 'Sửa chuyên khoa'),
        backgroundColor: const Color(0xFF38A3A5),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildImagePicker(),
              const SizedBox(height: 20),
              _buildTextField(_nameCtrl, 'Tên chuyên khoa', Icons.medical_services, required: true),
              _buildTextField(_descriptionCtrl, 'Mô tả ngắn', Icons.description, maxLines: 2),
              _buildTextField(_overviewCtrl, 'Tổng quan', Icons.info_outline, maxLines: 4),
              _buildTextField(_servicesCtrl, 'Dịch vụ cung cấp', Icons.list_alt, maxLines: 4),
              _buildTextField(_technologyCtrl, 'Công nghệ & Trang thiết bị', Icons.settings_input_component, maxLines: 4),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: (_isSaving || _isUploading) ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38A3A5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text('LƯU CHUYÊN KHOA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _isUploading ? null : _pickImage,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(_imageUrl!, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
              )
            else if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_selectedImage!, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('Nhấn để chọn ảnh', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            if (_isUploading)
              Container(
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16)),
                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {bool required = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF38A3A5)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: required ? (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập $label' : null : null,
      ),
    );
  }
}
