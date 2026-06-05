import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/app_ratings/data/model/app_rating_model.dart';
import 'package:flutter_user_app/features/admin/dashboard/presentation/widgets/admin_widgets.dart';
import 'package:flutter_user_app/features/admin/dashboard/data/models/dashboard_models.dart' hide PaginationModel; // Added import

class AdminAppRatingsScreen extends StatefulWidget {
  const AdminAppRatingsScreen({super.key});

  @override
  State<AdminAppRatingsScreen> createState() => _AdminAppRatingsScreenState();
}

class _AdminAppRatingsScreenState extends State<AdminAppRatingsScreen> {
  final ApiService _apiService = ApiService.create();
  
  bool _isLoading = true;
  String? _error;
  List<AppRatingModel> _ratings = [];
  AppRatingStats? _stats;
  PaginationModel? _pagination;
  
  // Filter/Sort state
  String _currentSort = 'newest'; // 'newest', 'rating_desc', 'rating_asc'

  @override
  void initState() {
    super.initState();
    debugPrint("ADMIN_RATINGS_VERSION_FINAL_FIX_LOADED"); // Verify code update
    _loadRatings();
  }

  Future<void> _loadRatings({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getAppRatings(
        page: page,
        limit: 20,
        sort: _currentSort,
      );
      
      final ratingsResponse = AppRatingsResponse.fromJson(response);
      
      setState(() {
        _ratings = ratingsResponse.ratings;
        _stats = ratingsResponse.stats;
        _pagination = ratingsResponse.pagination;
        _isLoading = false;
      });
      
      // Fetch details for users not populated
      _fetchMissingUserDetails();
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMissingUserDetails() async {
    final List<AppRatingModel> updatedRatings = List.from(_ratings);
    bool hasUpdates = false;

    // Create a list of futures to fetch data in parallel
    final futures = <Future<void>>[];

    for (int i = 0; i < updatedRatings.length; i++) {
      final rating = updatedRatings[i];
      if ((rating.userName == null || rating.userName == 'Unknown User') && rating.userId != null) {
        futures.add(_fetchSingleUser(rating, i, updatedRatings).then((updated) {
           if (updated) hasUpdates = true;
        }));
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
      if (mounted && hasUpdates) {
        setState(() {
          _ratings = updatedRatings;
        });
      }
    }
  }

  Future<bool> _fetchSingleUser(AppRatingModel rating, int index, List<AppRatingModel> list) async {
    String? name;
    String? image;
    List<String> errors = [];

    try {
      if (rating.userType == 'Temple') {
        try {
          final temple = await _apiService.getTempleById(rating.userId!);
          name = temple.name;
          image = temple.profilePic;
        } catch (e) {
          errors.add("Temple: ${e.toString().split(':').last.trim()}");
        }
      } else if (rating.userType == 'Creator') {
        try {
          final creator = await _apiService.getCreatorById(rating.userId!);
          name = creator.creatorName;
          image = creator.profilePic;
        } catch (e) {
          errors.add("Creator: ${e.toString().split(':').last.trim()}");
        }
      } else {
        // User Type
        // 1. Try Admin Endpoint first (most reliable for admins)
        try {
          final user = await _apiService.getAdminUserById(rating.userId!);
          name = user['name'] ?? user['fullName'] ?? user['firstName'] ?? user['username'];
          image = user['image'] ?? user['profilePic'];
        } catch (e) {
          errors.add("AdminUser: ${e.toString().split(':').last.trim()}");
          
          // 2. Fallback to Standard Endpoint
          try {
            final user = await _apiService.getUserById(rating.userId!);
            name = user['name'] ?? user['fullName'] ?? user['firstName'] ?? user['username'];
            image = user['image'] ?? user['profilePic'];
          } catch (e2) {
             errors.add("User: ${e2.toString().split(':').last.trim()}");
             
             // 3. Last Resort: Client Search
             try {
                final response = await _apiService.getClientList(search: rating.userId!, type: 'all', limit: 1);
                final clientResponse = ClientListResponse.fromJson(response);
                if (clientResponse.clients.isNotEmpty) {
                   final match = clientResponse.clients.firstWhere((c) => c.id == rating.userId, orElse: () => clientResponse.clients.first);
                   name = match.name;
                   image = match.image;
                }
             } catch (_) {}
          }
        }
      }

      // 4. Blind Type Check (if name still null)
      if (name == null) {
         if (rating.userType != 'Temple') {
            try {
               final temple = await _apiService.getTempleById(rating.userId!);
               name = temple.name;
               image = temple.profilePic;
            } catch (_) {}
         }
         if (name == null && rating.userType != 'Creator') {
            try {
               final creator = await _apiService.getCreatorById(rating.userId!);
               name = creator.creatorName;
               image = creator.profilePic;
            } catch (_) {}
         }
      }

      if (name != null) {
        list[index] = rating.copyWith(
          userName: name,
          userImage: image,
        );
        return true;
      } else {
         // Clean error message
         String detailedError = errors.isNotEmpty ? errors.first : "Not Found";
         if (detailedError.contains("404")) detailedError = "User Not Found";
         if (detailedError.contains("403")) detailedError = "Access Denied";
         
         debugPrint("Failed to resolve ${rating.userId}: $errors");
         
         // 5. Final Fallback: Fetch latest 100 clients and search locally (Hack for backend search limitations)
         try {
            final dump = await _apiService.getClientList(type: 'all', limit: 100);
            final clients = ClientListResponse.fromJson(dump).clients;
            
            final match = clients.firstWhere(
               (c) => c.id == rating.userId, 
               orElse: () => clients.firstWhere((c) => false, orElse: () => ClientModel(id: '', name: '', email: '', phone: '', location: '', status: '', type: '', isDeactivated: false, userId: '')), // Dummy
            );
            
            if (match.id.isNotEmpty) {
               name = match.name;
               image = match.image;
            }
         } catch (e) {
            debugPrint("Fallback client list fetch failed: $e");
         }

         if (name != null) {
            list[index] = rating.copyWith(
               userName: name,
               userImage: image,
            );
            return true;
         }

         list[index] = rating.copyWith(
            userName: "Unknown ($detailedError)", 
            // Keep original image if any, asking UI to handle broken URL
         );
         return true;
      }
    } catch (e) {
      debugPrint("Critical error in _fetchSingleUser: $e");
    }
    return false;
  }

  void _onSortChanged(String newSort) {
    if (_currentSort != newSort) {
      setState(() {
        _currentSort = newSort;
      });
      _loadRatings(page: 1);
    }
  }

  void _onPageChanged(int newPage) {
    if (_pagination != null && newPage >= 1 && newPage <= _pagination!.totalPages) {
      _loadRatings(page: newPage);
    }
  }

  Color _getRatingColor(int rating) {
    if (rating >= 4) return Colors.green;
    if (rating == 3) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC), // Admin background color
      body: RefreshIndicator(
        onRefresh: _loadRatings,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Reusing AdminHeader but customized for Ratings
              AdminHeader(
                onBackPressed: () => Navigator.pop(context),
                title: "App Ratings",
                showSearch: false, // Or implement search later
                filters: Row(
                  children: [
                     _buildSortDropdown(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Cards
                    if (_stats != null)
                      Row(
                        children: [
                          StatCard(
                            title: "Average Rating",
                            value: _stats!.averageRating.toStringAsFixed(1),
                            icon: Icons.star,
                            iconColor: Colors.amber,
                            iconBgColor: Colors.amber.withOpacity(0.1),
                          ),
                          const SizedBox(width: 16),
                          StatCard(
                            title: "Total Reviews",
                            value: _stats!.totalRatings.toString(),
                            icon: Icons.reviews,
                            iconColor: Colors.blue,
                            iconBgColor: Colors.blue.withOpacity(0.1),
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 24),

                    // Ratings Table
                    if (_isLoading)
                       const Center(child: CircularProgressIndicator())
                    else if (_error != null)
                       Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
                    else if (_ratings.isEmpty)
                       const Center(
                         child: Padding(
                           padding: EdgeInsets.all(32.0),
                           child: Text("No ratings found.", style: TextStyle(color: Colors.grey)),
                         ),
                       )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Latest Reviews (${_pagination?.total ?? 0})", 
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                             ),
                             const SizedBox(height: 24),
                             
                             ListView.separated(
                               shrinkWrap: true,
                               physics: const NeverScrollableScrollPhysics(),
                               itemCount: _ratings.length,
                               separatorBuilder: (_, __) => const Divider(height: 32),
                               itemBuilder: (context, index) {
                                 final rating = _ratings[index];
                                 return _buildRatingItem(rating);
                               },
                             ),

                             const SizedBox(height: 24),
                             // Pagination
                             if (_pagination != null)
                               Row(
                                 mainAxisAlignment: MainAxisAlignment.end,
                                 children: [
                                   IconButton(
                                     icon: const Icon(Icons.chevron_left),
                                     onPressed: _pagination!.page > 1 ? () => _onPageChanged(_pagination!.page - 1) : null,
                                   ),
                                   Text("Page ${_pagination!.page} of ${_pagination!.totalPages}"),
                                   IconButton(
                                     icon: const Icon(Icons.chevron_right),
                                     onPressed: _pagination!.page < _pagination!.totalPages ? () => _onPageChanged(_pagination!.page + 1) : null,
                                   ),
                                 ],
                               ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: PopupMenuButton<String>(
        initialValue: _currentSort,
        onSelected: _onSortChanged,
        child: Row(
          children: [
            const Icon(Icons.sort, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(_getSortLabel(_currentSort), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
          ],
        ),
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'newest', child: Text("Newest First")),
          const PopupMenuItem(value: 'oldest', child: Text("Oldest First")),
          const PopupMenuItem(value: 'rating_desc', child: Text("Highest Rating")),
          const PopupMenuItem(value: 'rating_asc', child: Text("Lowest Rating")),
        ],
      ),
    );
  }

  String _getSortLabel(String sort) {
    switch (sort) {
      case 'newest': return 'Newest';
      case 'oldest': return 'Oldest';
      case 'rating_desc': return 'Highest';
      case 'rating_asc': return 'Lowest';
      default: return 'Sort By';
    }
  }

  Widget _buildRatingItem(AppRatingModel rating) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[200],
              backgroundImage: rating.userImage != null && rating.userImage!.isNotEmpty 
                  ? NetworkImage(rating.userImage!) 
                  : null,
              child: rating.userImage == null || rating.userImage!.isEmpty 
                  ? const Icon(Icons.person, color: Colors.grey) 
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        rating.userName ?? 'Unknown User',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getRatingColor(rating.rating).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Text(
                              rating.rating.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                color: _getRatingColor(rating.rating),
                                fontSize: 12
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.star, size: 12, color: _getRatingColor(rating.rating)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        rating.userType ?? 'User',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      // Platform icon or text
                      if (rating.platform != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(rating.platform!, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                        ),
                      const Spacer(),
                      if (rating.createdAt != null)
                        Text(
                          DateFormat('MMM d, yyyy').format(rating.createdAt!),
                          style: TextStyle(color: Colors.grey[400], fontSize: 11),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (rating.comment != null && rating.comment!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            rating.comment!,
            style: TextStyle(color: Colors.grey[800], fontSize: 13, height: 1.4),
          ),
        ],
      ],
    );
  }
}
