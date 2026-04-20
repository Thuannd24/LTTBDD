import 'package:flutter/material.dart';
import 'package:tbdd/core/constants/app_strings.dart';
import 'package:tbdd/features/admin/data/specialty_service.dart';
import 'package:tbdd/core/models/specialty_model.dart';
import 'package:tbdd/features/admin/presentation/screens/specialty_form_screen.dart';

class SpecialtiesListScreen extends StatefulWidget {
  const SpecialtiesListScreen({super.key});

  @override
  State<SpecialtiesListScreen> createState() => _SpecialtiesListScreenState();
}

class _SpecialtiesListScreenState extends State<SpecialtiesListScreen> {
  final SpecialtyService _service = SpecialtyService();
  List<Specialty> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final list = await _service.fetchAll();
      setState(() {
        _items = list;
      });
    } catch (e) {
      debugPrint('Load specialties error: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể tải chuyên khoa')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onCreate() async {
    final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const SpecialtyFormScreen()));
    if (res == true) _load();
  }

  void _onEdit(Specialty s) async {
    final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => SpecialtyFormScreen(specialty: s)));
    if (res == true) _load();
  }

  void _onDelete(Specialty s) async {
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Xác nhận'),
      content: Text('Bạn có chắc muốn xóa chuyên khoa "${s.name}"?'),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Xóa'))],
    ));
    if (ok == true) {
      try {
        await _service.delete(s.id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa thành công')));
        _load();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa thất bại')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.specialties),
        actions: [IconButton(onPressed: _onCreate, icon: const Icon(Icons.add))],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final s = _items[index];
            return Card(
              child: ListTile(
                leading: s.image != null ? Image.network(s.image!, width: 56, height: 56, fit: BoxFit.cover) : const Icon(Icons.medical_services),
                title: Text(s.name),
                subtitle: s.description != null ? Text(s.description!) : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(onPressed: () => _onEdit(s), icon: const Icon(Icons.edit)),
                    IconButton(onPressed: () => _onDelete(s), icon: const Icon(Icons.delete, color: Colors.red)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
