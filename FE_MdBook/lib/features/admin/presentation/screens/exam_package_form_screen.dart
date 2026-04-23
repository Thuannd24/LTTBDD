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
                ? 'Cap nhat goi kham thanh cong'
                : 'Tao goi kham thanh cong',
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
      ).showSnackBar(SnackBar(content: Text('Khong the luu goi kham: $e')));
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
        title: Text(_isEdit ? 'Sua goi kham' : 'Tao goi kham'),
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
              label: 'Ma goi kham',
              icon: Icons.qr_code_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui long nhap ma goi kham';
                }
                return null;
              },
            ),
            _buildTextField(
              controller: _nameController,
              label: 'Ten goi kham',
              icon: Icons.medical_services_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui long nhap ten goi kham';
                }
                return null;
              },
            ),
            _buildTextField(
              controller: _minutesController,
              label: 'Thoi gian du kien (phut)',
              icon: Icons.timer_outlined,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui long nhap thoi gian du kien';
                }
                final minutes = int.tryParse(value.trim());
                if (minutes == null || minutes <= 0) {
                  return 'Thoi gian phai lon hon 0';
                }
                return null;
              },
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Trang thai',
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
                    child: Text('Dang hoat dong'),
                  ),
                  DropdownMenuItem(value: 'INACTIVE', child: Text('Tam dung')),
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
              label: 'Mo ta',
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
                        _isEdit ? 'CAP NHAT GOI KHAM' : 'TAO GOI KHAM',
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
