import 'package:flutter/material.dart';
import 'package:tbdd/core/models/exam_package_model.dart';
import 'package:tbdd/features/admin/data/exam_package_admin_service.dart';

class ExamPackageFormScreen extends StatefulWidget {
  final ExamPackageModel? examPackage;

  const ExamPackageFormScreen({super.key, this.examPackage});

  @override
  State<ExamPackageFormScreen> createState() => _ExamPackageFormScreenState();
}

class _ExamPackageFormScreenState extends State<ExamPackageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ExamPackageAdminService _service = ExamPackageAdminService();

  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _minutesController;
  late final TextEditingController _descriptionController;

  late String _selectedStatus;
  bool _isSaving = false;

  bool get _isEdit => widget.examPackage != null;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(
      text: widget.examPackage?.code ?? '',
    );
    _nameController = TextEditingController(
      text: widget.examPackage?.name ?? '',
    );
    _minutesController = TextEditingController(
      text: widget.examPackage?.estimatedTotalMinutes?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.examPackage?.description ?? '',
    );
    _selectedStatus = widget.examPackage?.status ?? 'ACTIVE';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _minutesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final estimatedMinutes = int.parse(_minutesController.text.trim());

    setState(() => _isSaving = true);

    try {
      if (_isEdit) {
        await _service.update(
          id: widget.examPackage!.id,
          code: _codeController.text.trim(),
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          estimatedTotalMinutes: estimatedMinutes,
          status: _selectedStatus,
        );
      } else {
        await _service.create(
          code: _codeController.text.trim(),
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          estimatedTotalMinutes: estimatedMinutes,
          status: _selectedStatus,
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Cập nhật gói khám thành công'
                : 'Tạo gói khám thành công',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể lưu gói khám: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(_isEdit ? 'Sửa gói khám' : 'Tạo gói khám'),
        backgroundColor: const Color(0xFF38A3A5),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextField(
              controller: _codeController,
              label: 'Mã gói khám',
              icon: Icons.qr_code_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập mã gói khám';
                }
                return null;
              },
            ),
            _buildTextField(
              controller: _nameController,
              label: 'Tên gói khám',
              icon: Icons.medical_services_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên gói khám';
                }
                return null;
              },
            ),
            _buildTextField(
              controller: _minutesController,
              label: 'Thời gian dự kiến (phút)',
              icon: Icons.timer_outlined,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập thời gian dự kiến';
                }
                final minutes = int.tryParse(value.trim());
                if (minutes == null || minutes <= 0) {
                  return 'Thời gian phải lớn hơn 0';
                }
                return null;
              },
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Trạng thái',
                  prefixIcon: const Icon(
                    Icons.toggle_on_outlined,
                    color: Color(0xFF38A3A5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'ACTIVE',
                    child: Text('Đang hoạt động'),
                  ),
                  DropdownMenuItem(value: 'INACTIVE', child: Text('Tạm dừng')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedStatus = value);
                  }
                },
              ),
            ),
            _buildTextField(
              controller: _descriptionController,
              label: 'Mô tả',
              icon: Icons.description_outlined,
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38A3A5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isEdit ? 'CẬP NHẬT GÓI KHÁM' : 'TẠO GÓI KHÁM',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF38A3A5)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
