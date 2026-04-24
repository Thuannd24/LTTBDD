import 'package:flutter/material.dart';
import 'package:tbdd/features/admin/presentation/screens/exam_packages_list_screen.dart';
import 'package:tbdd/features/auth/data/auth_service.dart';
import 'package:tbdd/features/auth/presentation/screens/login_screen.dart';

import '../../../../core/models/user_model.dart';
import 'admin_schedule_screen.dart';
import 'specialties_list_screen.dart';
import 'user_management_screen.dart';
import 'package:tbdd/features/chat/data/chat_socket_service.dart';
import 'package:tbdd/features/chat/data/profile_service.dart';
import 'package:tbdd/features/user/appointment/data/appointment_service.dart';
import 'package:tbdd/core/models/appointment_request_model.dart';

class AdminDashboard extends StatefulWidget {
  final UserProfile? user;

  const AdminDashboard({super.key, this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _authService = AuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;
  int _doctorCount = 0;
  int _patientCount = 0;
  int _appointmentCount = 0;
  List<AppointmentRequestModel> _recentRequests = [];
  bool _isLoadingStats = true;

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard_rounded, 'label': 'Tổng quan'},
    {'icon': Icons.calendar_month_rounded, 'label': 'Lịch khám'},
    {'icon': Icons.people_alt_rounded, 'label': 'Người dùng'},
    {'icon': Icons.inventory_2_rounded, 'label': 'Gói khám'},
    {'icon': Icons.medical_services_rounded, 'label': 'Chuyên khoa'},
    {'icon': Icons.bar_chart_rounded, 'label': 'Thống kê'},
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    try {
      // 1. Fetch Users
      final users = await _authService.getAllUsers();
      int doctors = 0;
      int patients = 0;
      for (final u in users) {
        if (u.isDoctor) doctors++;
        else if (u.isUser) patients++;
      }

      // 2. Fetch Appointments (using pending requests as a proxy for recent activity)
      final appointmentService = AppointmentService();
      final pendingRequests = await appointmentService.getPendingRequests();

      if (!mounted) return;
      setState(() {
        _doctorCount = doctors;
        _patientCount = patients;
        _appointmentCount = pendingRequests.length;
        _recentRequests = pendingRequests.take(5).toList();
        _isLoadingStats = false;
      });
    } catch (e) {
      debugPrint('Error loading admin stats: $e');
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
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
                        const AdminScheduleScreen(),
                        UserManagementScreen(onUserAdded: _loadStats),
                        const ExamPackagesListScreen(),
                        const SpecialtiesListScreen(),
                        _buildStatisticsTab(),
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

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thống kê hệ thống', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
            ),
            child: const Center(child: Text('Biểu đồ tăng trưởng (Sắp ra mắt)', style: TextStyle(color: Colors.grey))),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({bool isDrawer = false}) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Column(
        children: [
          const SizedBox(height: 48),
          _buildLogo(),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              itemCount: _menuItems.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      if (index == 0) _loadStats();
                      if (isDrawer) Navigator.pop(context);
                    },
                    selected: isSelected,
                    selectedTileColor: const Color(0xFF38A3A5).withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: Icon(
                      _menuItems[index]['icon'] as IconData,
                      color: isSelected ? const Color(0xFF38A3A5) : Colors.grey[500],
                      size: 22,
                    ),
                    title: Text(
                      _menuItems[index]['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[400],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
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

  Widget _buildLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF38A3A5), Color(0xFF22577A)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        const Text(
          'MED ADMIN',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: const Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF38A3A5),
            radius: 18,
            child: Text(
              (widget.user?.username != null && widget.user!.username!.isNotEmpty)
                  ? widget.user!.username![0].toUpperCase()
                  : 'A',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.user?.fullName ?? widget.user?.username ?? 'Admin',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text('Quản trị viên', style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey, size: 18),
            onPressed: () async {
              ProfileService.instance.clearCache();
              ChatSocketService().disconnect();
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
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 1, offset: Offset(0, 1))],
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          Text(
            _menuItems[_selectedIndex]['label'] as String,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const Spacer(),
          _buildHeaderIcon(Icons.search_rounded),
          const SizedBox(width: 12),
          _buildHeaderIcon(Icons.notifications_none_rounded, hasBadge: true),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, {bool hasBadge = false}) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
          child: Icon(icon, color: Colors.grey[600], size: 20),
        ),
        if (hasBadge)
          Positioned(
            right: 0, top: 0,
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
            ),
          ),
      ],
    );
  }

  Widget _buildOverviewTab(bool isMobile) {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF38A3A5)));
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeAdmin(),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 700 ? 2 : 1);
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 2.2,
                  children: [
                    _buildStatCard('Bác sĩ hệ thống', '$_doctorCount', Icons.person_add_rounded, const Color(0xFF38A3A5)),
                    _buildStatCard('Tổng bệnh nhân', '$_patientCount', Icons.people_alt_rounded, const Color(0xFF22577A)),
                    _buildStatCard('Lịch hẹn đang chờ', '$_appointmentCount', Icons.pending_actions_rounded, const Color(0xFFFFB703)),
                    _buildStatCard('Doanh thu hệ thống', '0M', Icons.account_balance_wallet_rounded, const Color(0xFF80ED99)),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildRecentAppointments()),
                if (!isMobile) const SizedBox(width: 24),
                if (!isMobile) Expanded(child: _buildQuickActions()),
              ],
            ),
            if (isMobile) ...[
              const SizedBox(height: 24),
              _buildQuickActions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeAdmin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chào buổi sáng, Quản trị viên!',
          style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tổng quan hệ thống MedBook',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAppointments() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Yêu cầu đặt lịch mới nhất', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => setState(() => _selectedIndex = 1), child: const Text('Xem tất cả')),
            ],
          ),
          const SizedBox(height: 20),
          if (_recentRequests.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Không có yêu cầu nào mới', style: TextStyle(color: Colors.grey))))
          else
            _buildModernTable(),
        ],
      ),
    );
  }

  Widget _buildModernTable() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentRequests.length,
      separatorBuilder: (context, index) => const Divider(height: 24, thickness: 0.5),
      itemBuilder: (context, index) {
        final req = _recentRequests[index];
        return Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF38A3A5).withValues(alpha: 0.1),
              child: const Icon(Icons.person_outline, color: Color(0xFF38A3A5), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID: ${req.id.substring(0, 8)}...', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('Bác sĩ: ${req.doctorId}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            _buildStatusChip(req.status),
          ],
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = status == 'PENDING' ? Colors.orange : (status == 'CONFIRMED' ? Colors.blue : Colors.green);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thao tác nhanh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildPremiumActionButton(Icons.person_add_rounded, 'Quản lý người dùng', 'Thêm mới bác sĩ/bệnh nhân', const Color(0xFF38A3A5), () => setState(() => _selectedIndex = 2)),
          const SizedBox(height: 16),
          _buildPremiumActionButton(Icons.inventory_2_rounded, 'Quản lý gói khám', 'Cập nhật dịch vụ y tế', Colors.orange, () => setState(() => _selectedIndex = 3)),
          const SizedBox(height: 16),
          _buildPremiumActionButton(Icons.bar_chart_rounded, 'Xem báo cáo chi tiết', 'Thống kê doanh thu & lượt khám', Colors.purple, () => setState(() => _selectedIndex = 5)),
        ],
      ),
    );
  }

  Widget _buildPremiumActionButton(IconData icon, String title, String sub, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[100]!), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(sub, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}
