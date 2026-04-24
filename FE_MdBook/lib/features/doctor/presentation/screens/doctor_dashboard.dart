import 'package:flutter/material.dart';
import 'package:tbdd/core/constants/app_strings.dart';
import 'package:tbdd/core/models/doctor_profile_model.dart';
import 'package:tbdd/core/models/user_model.dart';
import 'package:tbdd/features/auth/data/auth_service.dart';
import 'package:tbdd/features/auth/presentation/screens/login_screen.dart';
import 'package:tbdd/features/doctor/data/doctor_service.dart';
import 'package:tbdd/features/doctor/presentation/screens/doctor_personal_info_screen.dart';
import 'package:tbdd/features/doctor/presentation/screens/doctor_profile_edit_screen.dart';
import 'package:tbdd/features/doctor/presentation/screens/doctor_schedule_screen.dart';

import 'package:tbdd/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:tbdd/features/chat/data/chat_socket_service.dart';
import 'package:tbdd/features/chat/data/profile_service.dart';
import 'package:tbdd/features/doctor/presentation/screens/doctor_appointment_screen.dart';

class DoctorDashboard extends StatefulWidget {
  final UserProfile? user;

  const DoctorDashboard({super.key, this.user});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final AuthService _authService = AuthService();
  final DoctorService _doctorService = DoctorService();

  DoctorProfile? _doctorInfo;
  bool _loadingDoctorProfile = true;
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard_rounded, 'label': AppStrings.overview},
    {'icon': Icons.calendar_month_rounded, 'label': AppStrings.workingSchedule},
    {'icon': Icons.event_note_rounded, 'label': 'Lịch hẹn'},
    {'icon': Icons.medical_services_rounded, 'label': AppStrings.professionalProfile},
    {'icon': Icons.person_rounded, 'label': AppStrings.personalInfo},
    {'icon': Icons.chat_rounded, 'label': AppStrings.messages},
  ];

  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
  }

  Future<void> _loadDoctorProfile() async {
    if (!mounted) {
      return;
    }

    setState(() => _loadingDoctorProfile = true);

    if (widget.user == null) {
      if (mounted) {
        setState(() => _loadingDoctorProfile = false);
      }
      return;
    }

    try {
      final doc = await _doctorService.getByUserId(widget.user!.userId);
      if (!mounted) {
        return;
      }
      setState(() {
        _doctorInfo = doc;
        _loadingDoctorProfile = false;
      });
    } catch (e) {
      debugPrint('Error loading doctor info: $e');
      if (!mounted) {
        return;
      }
      setState(() {
        _doctorInfo = null;
        _loadingDoctorProfile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 900;
    String doctorId = _doctorInfo?.id ?? 'doctor_id';

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
                        DoctorScheduleScreen(
                          doctorId: doctorId,
                          isDoctorProfileLoading: _loadingDoctorProfile,
                          onOpenProfile: () => setState(() => _selectedIndex = 3),
                        ),
                        DoctorAppointmentScreen(doctorId: doctorId),
                        DoctorProfileEditScreen(
                          userId: widget.user?.userId ?? '',
                          doctorId: _doctorInfo?.id,
                          onSaved: _loadDoctorProfile,
                        ),
                        DoctorPersonalInfoScreen(user: widget.user),
                        const ChatListScreen(isEmbedded: true),
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
      width: 280,
      color: const Color(0xFF1E293B),
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
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      if (isDrawer) {
                        Navigator.pop(context);
                      }
                    },
                    selected: isSelected,
                    selectedTileColor: const Color(0xFF38A3A5).withValues(alpha: 0.12),
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
          _buildLogoutMenu(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF38A3A5),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38A3A5).withValues(alpha: 0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        const Text(
          AppStrings.medbook,
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
      ],
    );
  }

  Widget _buildLogoutMenu() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: InkWell(
        onTap: () async {
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
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF38A3A5),
              backgroundImage: widget.user?.avatar != null && widget.user!.avatar!.isNotEmpty
                  ? NetworkImage(widget.user!.avatar!)
                  : null,
              child: widget.user?.avatar == null || widget.user!.avatar!.isEmpty
                  ? const Icon(Icons.person, color: Colors.white, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_doctorInfo?.degree != null ? '${_doctorInfo!.degree}. ' : ''}${(_doctorInfo?.fullName != null && _doctorInfo!.fullName != 'Bác sĩ') ? _doctorInfo!.fullName : (widget.user?.fullName ?? 'Bác sĩ')}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _doctorInfo?.position ?? AppStrings.specialistDoctor,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.logout, color: Colors.grey, size: 18),
          ],
        ),
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
            _menuItems[_selectedIndex]['label'],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
          const Spacer(),
          _buildTopActionButton(Icons.search_rounded),
          const SizedBox(width: 12),
          _buildTopActionButton(Icons.notifications_none_rounded, hasNotification: true),
        ],
      ),
    );
  }

  Widget _buildTopActionButton(IconData icon, {bool hasNotification = false}) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey[50], shape: BoxShape.circle),
          child: Icon(icon, color: Colors.grey[600], size: 22),
        ),
        if (hasNotification)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOverviewTab(bool isMobile) {
    String displayName = (_doctorInfo?.fullName != null && _doctorInfo!.fullName != 'Bác sĩ') 
        ? _doctorInfo!.fullName 
        : (widget.user?.fullName ?? 'Bác sĩ');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner
          _buildWelcomeBanner(displayName),
          const SizedBox(height: 32),
          
          // Stats Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 2 : 1);
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 2.5,
                children: [
                  _buildStatsCard('Lịch hẹn hôm nay', '12', Icons.calendar_today_rounded, const Color(0xFF38A3A5), '+3 mới'),
                  _buildStatsCard('Tổng bệnh nhân', '1,248', Icons.people_alt_rounded, const Color(0xFF22577A), '+5 tháng này'),
                  _buildStatsCard('Đánh giá trung bình', '4.9', Icons.star_rounded, const Color(0xFFFFB703), '240 lượt'),
                  _buildStatsCard('Doanh thu dự kiến', '15.5M', Icons.account_balance_wallet_rounded, const Color(0xFF80ED99), 'Tháng này'),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          
          // Main Content Area
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildAppointmentsPreview()),
              if (!isMobile) const SizedBox(width: 24),
              if (!isMobile) Expanded(child: _buildSchedulePreview()),
            ],
          ),
          if (isMobile) const SizedBox(height: 24),
          if (isMobile) _buildSchedulePreview(),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF22577A), Color(0xFF38A3A5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38A3A5).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chào mừng quay trở lại,',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bác sĩ $name',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Bạn có 5 lịch hẹn mới cần xác nhận trong hôm nay.',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          if (MediaQuery.of(context).size.width > 600)
            const Icon(Icons.medication_liquid, color: Colors.white, size: 80),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String label, String value, IconData icon, Color color, String trend) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                Text(
                  trend,
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsPreview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Lịch hẹn gần đây', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 2),
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Placeholder for real list
          _buildAppointmentItem('Nguyễn Văn An', '08:00 - 08:30', 'Gói khám cơ bản', 'Đang chờ'),
          _buildAppointmentItem('Trần Thị Bình', '09:00 - 09:30', 'Khám tim mạch', 'Đã xác nhận'),
          _buildAppointmentItem('Lê Hoàng Long', '10:30 - 11:00', 'Tư vấn nội tiết', 'Đã khám'),
        ],
      ),
    );
  }

  Widget _buildAppointmentItem(String patient, String time, String package, String status) {
    Color statusColor = status == 'Đang chờ' ? Colors.orange : (status == 'Đã xác nhận' ? Colors.blue : Colors.green);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.person_outline, color: Color(0xFF38A3A5), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patient, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('$time • $package', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulePreview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cấu hình ca làm việc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text(
            'Bạn chưa thiết lập lịch làm việc định kỳ cho tuần tới.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => setState(() => _selectedIndex = 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38A3A5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Thiết lập ngay', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

}
