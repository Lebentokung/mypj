import 'package:flutter/material.dart';
import 'package:flutter_application_2/core/theme/app_colors.dart';
import 'package:flutter_application_2/presentation/screen/notification/map_screen.dart';
import 'package:flutter_application_2/presentation/screen/notification/profile_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_application_2/presentation/screen/notification/notification_main_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key, required this.username});

  final String username;

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 1;

  // static const int marketTab = 0;
  // static const int taskTab = 1;
  // static const int profileTab = 2;
  // static const int notificationTab = 3;
  // static const int themeTab = 4;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      ProfileScreen(username: widget.username),
      const NotificationMainScreen(),
      const MapScreen(),
    ];
  }

  List<BottomNavigationBarItem> _buildNavBarItems() {
    return [
      _iconNavBarItem(Icons.person, 'Profile'),
      _iconNavBarItem(Icons.qr_code_scanner, 'Scan'),
      _iconNavBarItem(Icons.map, 'Map'),
    ];
  }

  BottomNavigationBarItem _iconNavBarItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: NavIcon(
        icon: Icon(icon, color: AppColors.textPrimary),
      ),
      activeIcon: NavActiveIcon(
        icon: Icon(icon, color: AppColors.textPrimary),
      ),
      label: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.textPrimary,
        unselectedItemColor: AppColors.textPrimary,
        selectedIconTheme: const IconThemeData(size: 22),
        unselectedIconTheme: const IconThemeData(size: 22),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        elevation: 8,
        items: _buildNavBarItems(),
      ),
    );
  }
}

class SvgIcon extends StatelessWidget {
  final String asset;
  final Color color;
  final double size;
  const SvgIcon({
    super.key,
    required this.asset,
    required this.color,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      width: size,
      height: size,
    );
  }
}

class NavActiveIcon extends StatelessWidget {
  final Widget icon;
  final Color? color;
  const NavActiveIcon({super.key, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: icon,
    );
  }
}

class NavIcon extends StatelessWidget {
  final Widget icon;
  final Color? color;
  const NavIcon({super.key, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(8.0), child: icon);
  }
}
