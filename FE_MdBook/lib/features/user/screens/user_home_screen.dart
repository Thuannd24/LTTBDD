import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../appointment/screens/booking_screen.dart';
import '../appointment/screens/appointment_list_screen.dart';
import '../../auth/presentation/screens/profile_screen.dart';
import '../../chat/presentation/screens/chat_list_screen.dart';
import '../appointment/screens/specialty_list_screen.dart';
import '../appointment/screens/specialty_detail_screen.dart';
import '../appointment/screens/doctor_detail_screen.dart';
import '../appointment/screens/doctor_list_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),
    const Center(child: Text('Hồ sơ y tế')),
    const AppointmentListScreen(),
    const Center(child: Text('Thông báo')),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        onPressed: () {
           Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatListScreen()),
          );
        },
        backgroundColor: const Color(0xFF38A3A5),
        elevation: 4,
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ) : null,
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

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF38A3A5), width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 22,
                          backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=david'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Clinical Sanctuary',
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Text(
                            'Hệ thống y tế quốc tế',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF38A3A5)),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
            _buildGreeting(),
            _buildSearchBar(),
            _buildSpecialties(context),
            _buildTopDoctors(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chào David 👋',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
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
        child: const TextField(
          decoration: InputDecoration(
            icon: Icon(Icons.search_rounded, color: Color(0xFF38A3A5)),
            hintText: AppStrings.searchHint,
            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialties(BuildContext context) {
    final List<Map<String, dynamic>> specialties = [
      {'name': 'Tim mạch', 'icon': Icons.favorite_rounded, 'color': const Color(0xFFE0F2F1)},
      {'name': 'NHI KHOA', 'icon': Icons.child_care_rounded, 'color': const Color(0xFFE8EAF6)},
      {'name': 'THẦN KINH', 'icon': Icons.psychology_rounded, 'color': const Color(0xFFFFF3E0)},
      {'name': 'NHÃN KHOA', 'icon': Icons.visibility_rounded, 'color': const Color(0xFFF1F8E9)},
    ];

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
          height: 125,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 24, bottom: 5),
            itemCount: specialties.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SpecialtyDetailScreen(specialtyName: specialties[index]['name']),
                    ),
                  );
                },
                child: Container(
                  width: 105,
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
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: specialties[index]['color'], shape: BoxShape.circle),
                        child: Icon(specialties[index]['icon'], color: const Color(0xFF38A3A5), size: 26),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        specialties[index]['name'].toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF4A4E69)),
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
    final List<Map<String, dynamic>> doctors = [
      {
        'name': 'BS. Julianne Moore',
        'specialty': 'Tim mạch',
        'rating': 4.9,
        'reviews': 120,
        'image': 'https://img.freepik.com/free-vector/doctor-character-background_1270-84.jpg',
        'price': 500000,
      },
      {
        'name': 'BS. Alan Cooper',
        'specialty': 'Thần kinh',
        'rating': 4.8,
        'reviews': 94,
        'image': 'https://img.freepik.com/free-vector/doctor-character-background_1270-84.jpg',
        'price': 600000,
      },
    ];

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
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            final doctor = doctors[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DoctorDetailScreen(doctor: doctor)),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[100]!),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 85, height: 85,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(18),
                        image: DecorationImage(image: NetworkImage(doctor['image']), fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFFFB74D), size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${doctor['rating']} (${doctor['reviews']})',
                                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            doctor['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF2D3142)),
                          ),
                          Text(
                            doctor['specialty'],
                            style: const TextStyle(color: Color(0xFF38A3A5), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Giá khám: ${doctor['price']}đ',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
