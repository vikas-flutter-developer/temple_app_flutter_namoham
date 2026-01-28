import 'package:flutter/material.dart';
import 'package:flutter_user_app/features/admin/dashboard/presentation/screens/admin_calendar_screen.dart';
import 'package:flutter_user_app/features/admin/dashboard/presentation/screens/admin_dashboard_screen.dart';
import 'package:flutter_user_app/features/admin/dashboard/presentation/screens/admin_donation_screen.dart';
import 'package:flutter_user_app/features/admin/dashboard/presentation/screens/admin_reports_screen.dart';
import 'package:flutter_user_app/features/admin/dashboard/presentation/screens/admin_messages_screen.dart';
import 'package:flutter_user_app/features/auth/login/presentation/screens/login_page.dart';
import 'package:flutter_user_app/core/helper/navigation_helper.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminMainLayout extends StatefulWidget {
  const AdminMainLayout({super.key});

  @override
  State<AdminMainLayout> createState() => _AdminMainLayoutState();
}

class _AdminMainLayoutState extends State<AdminMainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const AdminDonationScreen(),
    const AdminCalendarScreen(),
    const AdminMessagesScreen(),
    const AdminReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background for the main area
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      const Icon(Icons.dashboard_customize, size: 28, color: Colors.black), // Logo Placeholder
                      const SizedBox(width: 8),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(text: "Dashboard"),
                            TextSpan(text: " v.01", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),

                // Menu Items
                _buildMenuItem(0, "Dashboard", Icons.dashboard_outlined),
                _buildMenuItem(1, "Donation", Icons.volunteer_activism_outlined),
                _buildMenuItem(2, "Calender", Icons.calendar_today_outlined), // Spelling as per Figma "Calender"
                _buildMenuItem(3, "Messages", Icons.message_outlined),
                _buildMenuItem(4, "Reports", Icons.receipt_long_outlined),

                const Spacer(),

                // Logout
                _buildMenuItem(5, "Logout", Icons.help_outline, isLogout: true),
                const SizedBox(height: 40),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        // 1. Call API Logout
        await ApiService.create().logout();
      } catch (e) {
        debugPrint('Logout API call failed: $e');
        // Continue with local logout anyway
      }

      // 2. Clear Local Data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      // Add any other specific keys to clear if needed, or use prefs.clear()

      // 3. Navigate to Login
      if (mounted) {
        navigateToPageAndRemoveUntil(context, const LoginPage());
      }
    }
  }

  Widget _buildMenuItem(int index, String title, IconData icon, {bool isLogout = false}) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        if (isLogout) {
          _handleLogout();
        } else {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A3FF) : Colors.transparent, // Blue color from Figma
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            if (!isLogout) ...[
               const Spacer(),
               Icon(
                 Icons.chevron_right,
                 color: isSelected ? Colors.white : Colors.transparent,
                 size: 18,
               )
            ]
          ],
        ),
      ),
    );
  }
}
