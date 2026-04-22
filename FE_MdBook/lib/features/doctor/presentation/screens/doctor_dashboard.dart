import 'package:flutter/material.dart';
import 'package:tbdd/core/constants/app_strings.dart';
import 'package:tbdd/features/auth/data/auth_service.dart';
import 'package:tbdd/features/auth/presentation/screens/login_screen.dart';
import 'package:tbdd/core/models/user_model.dart';
import 'package:tbdd/features/doctor/data/doctor_service.dart';
import 'package:tbdd/core/models/doctor_profile_model.dart';
import 'package:tbdd/features/doctor/presentation/screens/doctor_profile_edit_screen.dart';
import 'package:tbdd/features/doctor/presentation/screens/doctor_schedule_screen.dart';
import 'package:tbdd/features/doctor/presentation/screens/doctor_personal_info_screen.dart';

import 'package:tbdd/features/chat/presentation/screens/chat_list_screen.dart';

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
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard_rounded, 'label': AppStrings.overview},
    {'icon': Icons.calendar_month_rounded, 'label': AppStrings.workingSchedule},
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
    if (widget.user != null) {
      try {
        final doc = await _doctorService.getByUserId(widget.user!.userId);
        setState(() {
          _doctorInfo = doc;
        });
      } catch (e) {
        debugPrint('Error loading doctor info: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 900;
    String doctorId = _doctorInfo?.userId ?? widget.user?.userId ?? '';

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
                        DoctorScheduleScreen(doctorId: doctorId),
                        DoctorProfileEditScreen(doctorId: doctorId),
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
                bool isSelected = _selectedIndex == index;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      if (isDrawer) Navigator.pop(context);
                    },
                    selected: isSelected,
                    selectedTileColor: const Color(0xFF38A3A5).withOpacity(0.12),
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
            boxShadow: [BoxShadow(color: const Color(0xFF38A3A5).withOpacity(0.3), blurRadius: 10)],
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
          await _authService.logout();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context, 
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false
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
            IconButton(icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
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
              decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
            ),
          )
      ],
    );
  }

  Widget _buildOverviewTab(bool isMobile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.whatsNewToday,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[800]),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 2 : 1);
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.2,
                children: [
                  _buildStatsCard(AppStrings.appointmentStat, '12', Icons.calendar_today_rounded, Colors.blue, AppStrings.threeNew),
                  _buildStatsCard(AppStrings.patientStat, '45', Icons.group_rounded, Colors.teal, AppStrings.fiveNew),
                  _buildStatsCard(AppStrings.reviewStat, '4.8', Icons.star_rounded, Colors.orange, AppStrings.oneTwentyTurns),
                  _buildStatsCard(AppStrings.incomeStat, '2.5M', Icons.payments_rounded, Colors.purple, AppStrings.thisMonth),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildAppointmentsPreview(),
              ),
              if (!isMobile) const SizedBox(width: 24),
              if (!isMobile)
                Expanded(
                  child: _buildSchedulePreview(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String label, String value, IconData icon, Color color, String trend) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              Text(trend, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsPreview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(AppStrings.recentAppointments, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () {}, child: const Text(AppStrings.viewAll)),
            ],
          ),
          const SizedBox(height: 16),
          const Center(child: Text(AppStrings.noAppointmentsToday, style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildSchedulePreview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(AppStrings.scheduleShiftConfig, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text(AppStrings.noRecurringShiftsSet, style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _selectedIndex = 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38A3A5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(AppStrings.setupNow, style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}
