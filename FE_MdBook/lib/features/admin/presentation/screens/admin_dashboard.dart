import 'package:flutter/material.dart';
import 'package:tbdd/features/auth/data/auth_service.dart';
import 'specialties_list_screen.dart';
import 'user_management_screen.dart';
import 'package:tbdd/features/auth/presentation/screens/login_screen.dart';

import '../../../../core/models/user_model.dart';

class AdminDashboard extends StatefulWidget {
  final UserProfile? user;
  const AdminDashboard({super.key, this.user});

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
  ];

  int _doctorCount = 0;
  int _patientCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final users = await _authService.getAllUsers();
    int dr = 0;
    int pt = 0;
    for (var u in users) {
      if (u.isDoctor) dr++;
      if (u.isUser) pt++;
    }
    if (!mounted) return;
    setState(() {
      _doctorCount = dr;
      _patientCount = pt;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F2F5),
      drawer: isMobile ? _buildSidebar(isDrawer: true) : null,
      body: SafeArea(
        child: Row(
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
                        const Center(child: Text('Lịch khám (Sắp ra mắt)')),
                        UserManagementScreen(onUserAdded: _loadStats),
                        const SpecialtiesListScreen(),
                        const Center(child: Text('Thống kê báo cáo (Sắp ra mắt)')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                      if (index == 0) _loadStats(); // Refresh stats when returning to Overview
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.user?.username ?? 'Admin', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const Text('Quản trị viên', style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey, size: 18),
            onPressed: () async {
              await _authService.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
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
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isMobile 
              ? Column(children: _buildStatCardsList(horizontal: false))
              : Row(children: _buildStatCardsList(horizontal: true)),
            const SizedBox(height: 24),
            if (isMobile) ...[
              _buildRecentAppointments(),
              const SizedBox(height: 24),
              _buildQuickActions(),
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
      ),
    );
  }

  List<Widget> _buildStatCardsList({required bool horizontal}) {
    final cards = [
      _buildStatCard('Bác sĩ', '$_doctorCount', Icons.person_add, Colors.blue, horizontal),
      const SizedBox(width: 16, height: 16),
      _buildStatCard('Bệnh nhân', '$_patientCount', Icons.people, Colors.green, horizontal),
      const SizedBox(width: 16, height: 16),
      _buildStatCard('Lịch hẹn', '0', Icons.calendar_today, Colors.orange, horizontal),
      const SizedBox(width: 16, height: 16),
      _buildStatCard('Doanh thu', '0M', Icons.attach_money, Colors.purple, horizontal),
    ];
    return cards;
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool horizontal) {
    Widget card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
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
    );

    return horizontal ? Expanded(child: card) : card;
  }

  Widget _buildRecentAppointments() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Lịch hẹn gần đây', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => setState(() => _selectedIndex = 1), child: const Text('Xem tất cả')),
            ],
          ),
          const SizedBox(height: 16),
          _buildTable(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thao tác nhanh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildActionButton(Icons.person_add_alt_1, 'Thêm Người dùng', const Color(0xFF38A3A5), onTap: () {
             setState(() => _selectedIndex = 2); // Go to User Management
          }),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[100]!), 
          borderRadius: BorderRadius.circular(10),
        ),
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

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
        columns: [
          DataColumn(label: Text('Bệnh nhân', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Bác sĩ', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: List.generate(3, (index) => DataRow(cells: [
          DataCell(Text('Bệnh nhân mẫu')),
          DataCell(Text('Bác sĩ A')),
          DataCell(
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0x1AFFFF00), // Solid hex color instead of withOpacity
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Chờ khám', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ])),
      ),
    );
  }

}
