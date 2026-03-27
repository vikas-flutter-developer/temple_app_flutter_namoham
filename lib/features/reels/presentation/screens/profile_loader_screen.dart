import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/temples/presentation/screens/temple_page.dart';
import 'package:flutter_user_app/features/creator/presentation/screens/creator_page.dart';

/// A screen that loads a profile (Temple or Creator) by ID and navigates to the appropriate page
class ProfileLoaderScreen extends StatefulWidget {
  final String userId;
  final String userType; // 'temple' or 'creator'

  const ProfileLoaderScreen({
    super.key,
    required this.userId,
    required this.userType,
  });

  @override
  State<ProfileLoaderScreen> createState() => _ProfileLoaderScreenState();
}

class _ProfileLoaderScreenState extends State<ProfileLoaderScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);

      final normalizedUserType = widget.userType.toLowerCase();

      if (normalizedUserType == 'temple') {
        final temple = await api.getTempleById(widget.userId);
        if (mounted) {
           // Provide a blank default values if the backend doesn't return everything
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TemplePage(templeModel: temple),
            ),
          );
        }
      } else if (normalizedUserType == 'creator') {
        final creator = await api.getCreatorById(widget.userId);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CreatorPage(creator: creator),
            ),
          );
        }
      } else {
        setState(() {
          _error = 'User Profile Coming Soon';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isLoading
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF29D0FF)),
                  SizedBox(height: 16),
                  Text(
                    'Loading profile...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _error ?? 'An error occurred',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
      ),
    );
  }
}
