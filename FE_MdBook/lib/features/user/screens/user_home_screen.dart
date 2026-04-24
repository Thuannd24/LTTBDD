import 'package:flutter/material.dart';
import 'package:tbdd/core/constants/app_strings.dart';
import 'package:tbdd/features/user/appointment/screens/booking_screen.dart';
import 'package:tbdd/features/user/appointment/screens/appointment_list_screen.dart';
import 'package:tbdd/features/auth/presentation/screens/profile_screen.dart';
import 'package:tbdd/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:tbdd/features/user/appointment/screens/specialty_list_screen.dart';
import 'package:tbdd/features/user/appointment/screens/specialty_detail_screen.dart';
import 'package:tbdd/features/user/appointment/screens/doctor_detail_screen.dart';
import 'package:tbdd/features/user/appointment/screens/doctor_list_screen.dart';
import 'package:tbdd/features/auth/data/auth_service.dart';
import 'package:tbdd/features/admin/data/specialty_service.dart';
import 'package:tbdd/features/doctor/data/doctor_service.dart';
import 'package:tbdd/core/models/user_model.dart';
import 'package:tbdd/core/models/specialty_model.dart';
import 'package:tbdd/core/models/doctor_profile_model.dart';
import 'package:tbdd/features/user/ai_chat/screens/ai_chat_screen.dart';

import 'package:tbdd/features/user/screens/patient_medical_record_screen.dart';
import 'package:tbdd/features/user/widgets/doctor_card.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedIndex = 0;
  bool _fabExpanded = false;

  final List<Widget> _pages = [
    const HomeContent(),
    const PatientMedicalRecordScreen(),
    const AppointmentListScreen(),
    const Center(child: Text('Thông báo')),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _fabExpanded = false;
    });
  }

  void _toggleFab() {
    setState(() => _fabExpanded = !_fabExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _pages[_selectedIndex],
          // Overlay để đóng FAB khi bấm ra ngoài
          if (_fabExpanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _fabExpanded = false),
                child: Container(color: Colors.black.withOpacity(0.25)),
              ),
            ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Mini FAB: AI tư vấn
                AnimatedScale(
                  scale: _fabExpanded ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: AnimatedOpacity(
                    opacity: _fabExpanded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                          ),
                          child: const Text(
                            'AI tư vấn triệu chứng',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FloatingActionButton.small(
                          heroTag: 'fab_ai',
                          onPressed: () {
                            setState(() => _fabExpanded = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AiChatScreen()),
                            );
                          },
                          backgroundColor: const Color(0xFF22577A),
                          elevation: 4,
                          child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Mini FAB: Chat với bác sĩ
                AnimatedScale(
                  scale: _fabExpanded ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  child: AnimatedOpacity(
                    opacity: _fabExpanded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                          ),
                          child: const Text(
                            'Chat với bác sĩ',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FloatingActionButton.small(
                          heroTag: 'fab_chat',
                          onPressed: () {
                            setState(() => _fabExpanded = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ChatListScreen()),
                            );
                          },
                          backgroundColor: const Color(0xFF38A3A5),
                          elevation: 4,
                          child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Main FAB
                FloatingActionButton(
                  heroTag: 'fab_main',
                  onPressed: _toggleFab,
                  backgroundColor: const Color(0xFF38A3A5),
                  elevation: 6,
                  child: AnimatedRotation(
                    turns: _fabExpanded ? 0.125 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      _fabExpanded ? Icons.close_rounded : Icons.add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF38A3A5),
          unselectedItemColor: Colors.grey[400],
          selectedFontSize: 11,
          unselectedFontSize: 11,
          showUnselectedLabels: true,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Trang chủ'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment_ind_outlined), label: 'Hồ sơ'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Đặt lịch'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'Thông báo'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Tài khoản'),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final SpecialtyService _specialtyService = SpecialtyService();
  final DoctorService _doctorService = DoctorService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<Specialty> _specialties = [];
  List<DoctorProfile> _doctors = [];
  UserProfile? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _specialtyService.fetchAll(),
        _doctorService.fetchAll(),
        _authService.getMyInfo(),
      ]);
      if (mounted) {
        setState(() {
          _specialties = results[0] as List<Specialty>;
          _doctors = results[1] as List<DoctorProfile>;
          _user = results[2] as UserProfile;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading home data: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String val) {
     if (val.isEmpty) return;
     // simple navigation to search results or list
     Navigator.push(
       context,
       MaterialPageRoute(builder: (context) => DoctorListScreen(searchQuery: val)),
     );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              _buildGreeting(),
              _buildSearchBar(),
              _buildSpecialties(context),
              _buildTopDoctors(context),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clinical Sanctuary',
                style: TextStyle(
                  color: Color(0xFF0D47A1),
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Hệ thống y tế quốc tế',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF38A3A5)),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chào ${_user?.firstName ?? 'bạn'} 👋',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
          ),
          SizedBox(height: 6),
          Text(
            AppStrings.homeQuestion,
            style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: TextField(
          controller: _searchCtrl,
          onSubmitted: _onSearch,
          decoration: const InputDecoration(
            icon: Icon(Icons.search_rounded, color: Color(0xFF38A3A5)),
            hintText: 'Tìm kiếm bác sĩ, chuyên khoa...',
            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialties(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                AppStrings.specialties,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SpecialtyListScreen(isGeneralView: true)),
                  );
                },
                child: const Text(
                  AppStrings.viewAll,
                  style: TextStyle(color: Color(0xFF38A3A5), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 24, bottom: 5),
            itemCount: _specialties.length,
            itemBuilder: (context, index) {
              final s = _specialties[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SpecialtyDetailScreen(specialty: s),
                    ),
                  );
                },
                child: Container(
                  width: 110,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: const Color(0xFF38A3A5).withOpacity(0.1), shape: BoxShape.circle),
                        child: s.image != null 
                          ? CircleAvatar(radius: 26, backgroundImage: NetworkImage(s.image!))
                          : const Icon(Icons.medical_services_rounded, color: Color(0xFF38A3A5), size: 26),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          s.name.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF4A4E69), overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopDoctors(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                AppStrings.topDoctors,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DoctorListScreen(isGeneralView: true)),
                  );
                },
                child: const Text(
                  AppStrings.seeMore,
                  style: TextStyle(color: Color(0xFF38A3A5), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: _doctors.length > 5 ? 5 : _doctors.length, // Show up to 5
          itemBuilder: (context, index) {
            final doctor = _doctors[index];
            return DoctorCard(
              doctor: doctor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DoctorDetailScreen(doctor: doctor)),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
