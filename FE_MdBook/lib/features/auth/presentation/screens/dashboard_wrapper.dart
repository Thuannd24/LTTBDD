import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../data/auth_service.dart';
import '../../../../core/models/user_model.dart';
import '../../../admin/presentation/screens/admin_dashboard.dart';
import '../../../doctor/presentation/screens/doctor_dashboard.dart';
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
    int retryCount = 0;
    const int maxRetries = 3;

    while (retryCount < maxRetries) {
      final profile = await _authService.getMyInfo();
      if (profile != null) {
        if (mounted) {
          setState(() {
            _userProfile = profile;
            _isLoading = false;
          });
        }
        return;
      }

      retryCount++;
      if (retryCount < maxRetries && mounted) {
        debugPrint('Retry loading user info ($retryCount/$maxRetries)...');
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    if (mounted) {
      setState(() {
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
      return const Scaffold(
        body: Center(child: Text(AppStrings.errorLoadingProfile)),
      );
    }

    if (_userProfile!.isAdmin) {
      return AdminDashboard(user: _userProfile);
    } else if (_userProfile!.isDoctor) {
      return DoctorDashboard(user: _userProfile);
    } else {
      return const UserHomeScreen();
    }
  }
}
