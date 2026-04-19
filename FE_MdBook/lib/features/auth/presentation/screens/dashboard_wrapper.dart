import 'package:flutter/material.dart';
import '../../data/auth_service.dart';
import '../../../../core/models/user_model.dart';
import '../../../admin/screens/admin_dashboard.dart';
import '../../../doctor/screens/doctor_dashboard.dart';
import '../../../user/screens/user_home_screen.dart';

class DashboardWrapper extends StatefulWidget {
  const DashboardWrapper({super.key});

  @override
  State<DashboardWrapper> createState() => _DashboardWrapperState();
}

class _DashboardWrapperState extends State<DashboardWrapper> {
  final AuthService _authService = AuthService();
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final profile = await _authService.getMyInfo();
    if (mounted) {
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfile == null) {
      // In real app, redirect to login
      return const Scaffold(
        body: Center(child: Text('Không thể tải thông tin người dùng')),
      );
    }

    if (_userProfile!.isAdmin) {
      return const AdminDashboard();
    } else if (_userProfile!.isDoctor) {
      return const DoctorDashboard();
    } else {
      return const UserHomeScreen(); // Patient/User dashboard
    }
  }
}
