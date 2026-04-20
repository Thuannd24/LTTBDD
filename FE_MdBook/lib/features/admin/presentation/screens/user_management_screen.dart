import 'package:flutter/material.dart';
import '../../../auth/data/auth_service.dart';
import '../../../../core/models/user_model.dart';

class UserManagementScreen extends StatefulWidget {
  final VoidCallback? onUserAdded;
  const UserManagementScreen({super.key, this.onUserAdded});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AuthService _authService = AuthService();
  List<UserProfile> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await _authService.getAllUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'USER';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm người dùng mới'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SizedBox(
            width: 450,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: firstNameController, decoration: const InputDecoration(labelText: 'Họ', border: OutlineInputBorder()))),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: lastNameController, decoration: const InputDecoration(labelText: 'Tên', border: OutlineInputBorder()))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(controller: usernameController, decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextFormField(controller: emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextFormField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'Vai trò', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'USER', child: Text('Người dùng (User)')),
                        DropdownMenuItem(value: 'DOCTOR', child: Text('Bác sĩ (Doctor)')),
                        DropdownMenuItem(value: 'ADMIN', child: Text('Quản trị viên (Admin)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedRole = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final result = await _authService.adminCreateUser(
                    username: usernameController.text,
                    email: emailController.text,
                    password: passwordController.text,
                    firstName: firstNameController.text,
                    lastName: lastNameController.text,
                    roles: [selectedRole],
                  );
                  
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result['message']), backgroundColor: result['success'] ? Colors.green : Colors.red),
                      );
                      _loadUsers();
                      if (result['success']) {
                        widget.onUserAdded?.call();
                      }
                    }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38A3A5)),
              child: const Text('Tạo tài khoản', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        backgroundColor: const Color(0xFF38A3A5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(0.0), // Remove outer padding for full view
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: ClipRRect(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F9FA)),
                            columns: const [
                              DataColumn(label: Text('Họ tên')),
                              DataColumn(label: Text('Username')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Vai trò')),
                              DataColumn(label: Text('Trạng thái')),
                            ],
                            rows: _users.map((user) => DataRow(cells: [
                              DataCell(Text('${user.firstName ?? ''} ${user.lastName ?? ''}')),
                              DataCell(Text(user.username)),
                              DataCell(Text(user.email)),
                              DataCell(
                                Wrap(
                                  spacing: 4,
                                  children: user.roles
                                    .where((r) => !r.startsWith('default-role') && !r.startsWith('offline_access') && !r.startsWith('uma_'))
                                    .map((r) => Chip(
                                      label: Text(r, style: const TextStyle(fontSize: 10, color: Colors.indigo)),
                                      backgroundColor: Colors.indigo.withOpacity(0.05),
                                      side: BorderSide.none,
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    )).toList(),
                                )
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text('Hoạt động', style: TextStyle(color: Colors.green, fontSize: 11)),
                                )
                              ),
                              /*
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () {}),
                                    IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () {}),
                                  ],
                                )
                              ),
                              */
                            ])).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
