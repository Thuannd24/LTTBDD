import 'package:flutter/material.dart';
import '../../auth/data/auth_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard_rounded, 'label': 'Tổng quan'},
    {'icon': Icons.calendar_month_rounded, 'label': 'Lịch khám'},
    {'icon': Icons.people_alt_rounded, 'label': 'Người dùng'},
    {'icon': Icons.medical_services_rounded, 'label': 'Chuyên khoa'},
    {'icon': Icons.bar_chart_rounded, 'label': 'Thống kê'},
    {'icon': Icons.settings_rounded, 'label': 'Cài đặt'},
  ];

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F2F5),
      drawer: isMobile ? _buildSidebar(isDrawer: true) : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(isMobile),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      _buildOverviewTab(isMobile),
                      _buildSchedulesTab(),
                      _buildUsersTab(),
                      _buildSpecialtiesTab(),
                      _buildStatsTab(),
                      const Center(child: Text('Cài đặt hệ thống')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({bool isDrawer = false}) {
    return Container(
      width: 260,
      color: const Color(0xFF1E1E2D),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF38A3A5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.medication_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'MEDBOOK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),
          Expanded(
            child: ListView.builder(
              itemCount: _menuItems.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                bool isSelected = _selectedIndex == index;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      if (isDrawer) Navigator.pop(context);
                    },
                    selected: isSelected,
                    selectedTileColor: const Color(0xFF38A3A5).withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: Icon(
                      _menuItems[index]['icon'],
                      color: isSelected ? const Color(0xFF38A3A5) : Colors.grey[400],
                    ),
                    title: Text(
                      _menuItems[index]['label'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[400],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildUserInfo(),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF38A3A5),
            child: Text('A', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Quản trị viên', style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white,
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          Text(
            _menuItems[_selectedIndex]['label'],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          const Icon(Icons.notifications_none_outlined, color: Colors.grey),
          const SizedBox(width: 12),
          if (!isMobile) const Text('19/04/2026', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile 
            ? Column(children: _buildStatCardsList())
            : Row(children: _buildStatCardsList()),
          const SizedBox(height: 24),
          if (isMobile) ...[
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildRecentAppointments(),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildRecentAppointments()),
                const SizedBox(width: 24),
                Expanded(child: _buildQuickActions()),
              ],
            ),
        ],
      ),
    );
  }

  List<Widget> _buildStatCardsList() {
    return [
      _buildStatCard('Bác sĩ', '1', Icons.person_add, Colors.blue),
      const SizedBox(width: 16, height: 16),
      _buildStatCard('Bệnh nhân', '0', Icons.people, Colors.green),
      const SizedBox(width: 16, height: 16),
      _buildStatCard('Lịch hẹn', '0', Icons.calendar_today, Colors.orange),
      const SizedBox(width: 16, height: 16),
      _buildStatCard('Doanh thu', '0M', Icons.attach_money, Colors.purple),
    ];
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      flex: MediaQuery.of(context).size.width < 900 ? 0 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAppointments() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Lịch hẹn gần đây', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildTable(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thao tác nhanh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildActionButton(Icons.person_add_alt_1, 'Thêm Bác sĩ', const Color(0xFF38A3A5), onTap: _showAddDoctorDialog),
          const SizedBox(height: 8),
          _buildActionButton(Icons.category, 'Chuyên khoa', Colors.indigo, onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[100]!), borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 13)),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showAddDoctorDialog() {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm Bác sĩ mới'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: firstNameController, decoration: const InputDecoration(labelText: 'Họ')),
                  TextFormField(controller: lastNameController, decoration: const InputDecoration(labelText: 'Tên')),
                  TextFormField(controller: usernameController, decoration: const InputDecoration(labelText: 'Username')),
                  TextFormField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                  TextFormField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu')),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _createDoctorAccount(
                  username: usernameController.text,
                  email: emailController.text,
                  firstName: firstNameController.text,
                  lastName: lastNameController.text,
                  password: passwordController.text,
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38A3A5)),
            child: const Text('Tạo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _createDoctorAccount({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    final result = await _authService.adminCreateUser(
      username: username,
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      roles: ['DOCTOR'],
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
    }
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Bệnh nhân', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Bác sĩ', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: List.generate(3, (index) => const DataRow(cells: [
          DataCell(Text('Dữ liệu mẫu')),
          DataCell(Text('Bác sĩ A')),
          DataCell(Text('Chờ khám', style: TextStyle(color: Colors.orange))),
        ])),
      ),
    );
  }

  Widget _buildSchedulesTab() => const Center(child: Text('Lịch khám'));
  Widget _buildUsersTab() => const Center(child: Text('Người dùng'));
  Widget _buildSpecialtiesTab() => const Center(child: Text('Chuyên khoa'));
  Widget _buildStatsTab() => const Center(child: Text('Thống kê'));
}
