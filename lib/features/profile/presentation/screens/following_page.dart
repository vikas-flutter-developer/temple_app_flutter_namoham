import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_appbar.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_text_widget.dart';
import '../../../../widgets/custom_widgets/follow_card.dart';

// Model class for follow items
class FollowItem {
  final String id; // Added ID
  final String name;
  final String location;
  final String distance;
  final double rating;
  final int reviews;
  final String image;
  final String username;
  final bool isPerson;
  final dynamic data; // Added to hold the full model (TempleModel or CreatorModel)

  FollowItem({
    this.id = '',
    required this.name,
    required this.location,
    this.distance = '',
    this.rating = 0.0,
    this.reviews = 0,
    required this.image,
    this.username = '',
    this.isPerson = false,
    this.data,
  });

  factory FollowItem.fromJson(Map<String, dynamic> json) {
    return FollowItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      distance: json['distance'] ?? '',
      rating: json['rating']?.toDouble() ?? 0.0,
      reviews: json['reviews'] ?? 0,
      image: json['image'] ?? '',
      username: json['username'] ?? '',
      isPerson: json['isPerson'] ?? false,
      data: json,
    );
  }
}

// RENAMED CLASS TO AVOID CONFLICT
class FollowingMockService {
  // List of images with structured data
  final List<Map<String, dynamic>> _followItems = [
    {
      'name': 'Shiv Mandir',
      'location': 'Varanasi',
      'distance': '500 mts Away',
      'rating': 5.0,
      'reviews': 150,
      'image':
      'https://tse4.mm.bing.net/th?id=OIP.pNCXDt0gEeYeMpanx7pSjQHaE8&pid=Api&P=0&h=180',
      'isPerson': false,
    },
    {
      'name': 'Shiv Mandir',
      'location': 'Varanasi',
      'distance': '500 mts Away',
      'rating': 5.0,
      'reviews': 150,
      'image':
      'http://images.unsplash.com/photo-1557062975-96113e46608b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=MnwxMjA3fDB8MXxzZWFyY2h8Mnx8aW5kaWFuJTIwdGVtcGxlfHwwfHx8fDE2Mjc4MDg1NzM&ixlib=rb-1.2.1&q=80&w=1080',
      'isPerson': false,
    },
    {
      'name': 'Shiv Mandir',
      'location': 'Varanasi',
      'distance': '500 mts Away',
      'rating': 5.0,
      'reviews': 150,
      'image':
      'http://images.unsplash.com/photo-1557062975-96113e46608b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=MnwxMjA3fDB8MXxzZWFyY2h8Mnx8aW5kaWFuJTIwdGVtcGxlfHwwfHx8fDE2Mjc4MDg1NzM&ixlib=rb-1.2.1&q=80&w=1080',
      'isPerson': false,
    },
    {
      'name': 'Shiv Mandir',
      'location': 'Varanasi',
      'distance': '500 mts Away',
      'rating': 5.0,
      'reviews': 150,
      'image':
      'http://images.unsplash.com/photo-1557062975-96113e46608b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=MnwxMjA3fDB8MXxzZWFyY2h8Mnx8aW5kaWFuJTIwdGVtcGxlfHwwfHx8fDE2Mjc4MDg1NzM&ixlib=rb-1.2.1&q=80&w=1080',
      'isPerson': false,
    },
    {
      'name': 'Shiv Mandir',
      'location': 'Varanasi',
      'distance': '500 mts Away',
      'rating': 5.0,
      'reviews': 150,
      'image':
      'http://images.unsplash.com/photo-1557062975-96113e46608b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=MnwxMjA3fDB8MXxzZWFyY2h8Mnx8aW5kaWFuJTIwdGVtcGxlfHwwfHx8fDE2Mjc4MDg1NzM&ixlib=rb-1.2.1&q=80&w=1080',
      'isPerson': false,
    },
    {
      'name': 'Shiv Mandir',
      'location': 'Varanasi',
      'distance': '500 mts Away',
      'rating': 5.0,
      'reviews': 150,
      'image':
      'http://images.unsplash.com/photo-1557062975-96113e46608b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=MnwxMjA3fDB8MXxzZWFyY2h8Mnx8aW5kaWFuJTIwdGVtcGxlfHwwfHx8fDE2Mjc4MDg1NzM&ixlib=rb-1.2.1&q=80&w=1080',
      'isPerson': false,
    },
  ];

  // Simulate API call with delay
  Future<List<FollowItem>> fetchFollowItems() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Convert the structured list to FollowItem objects
    return _followItems.map((item) => FollowItem.fromJson(item)).toList();
  }
}

class FollowingsScreen extends StatefulWidget {
  const FollowingsScreen({Key? key}) : super(key: key);

  @override
  State<FollowingsScreen> createState() => _FollowingsScreenState();
}

class _FollowingsScreenState extends State<FollowingsScreen> {
  // Use the Renamed Service
  final FollowingMockService _apiService = FollowingMockService();
  List<FollowItem> _followItems = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final items = await _apiService.fetchFollowItems();
      setState(() {
        _followItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Show error if needed
    }
  }

  List<FollowItem> get _filteredItems {
    if (_searchQuery.isEmpty) {
      return _followItems;
    }
    return _followItems
        .where((item) =>
    item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        item.location.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextWidget(
              title: 'Following',
              subtitle: 'You are following them',
            ),
            const SizedBox(height: 24.0),
            SearchBar(
              elevation: WidgetStateProperty.all(1),
              hintText: 'Search...',
              padding: const WidgetStatePropertyAll<EdgeInsets>(
                  EdgeInsets.symmetric(horizontal: 20)),
              leading: Icon(Icons.search,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return FollowCard(
                    item: item,
                    onUnfollowPressed: () {
                      // Handle unfollow action
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Unfollowed ${item.name}'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}