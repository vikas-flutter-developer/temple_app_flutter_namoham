  import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../provider/app_rating_provider.dart';

class AppRatingScreen extends StatefulWidget {
  const AppRatingScreen({Key? key}) : super(key: key);

  @override
  State<AppRatingScreen> createState() => _AppRatingScreenState();
}

class _AppRatingScreenState extends State<AppRatingScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppRatingProvider.create(),
      child: const _AppRatingScreenContent(),
    );
  }
}

class _AppRatingScreenContent extends StatefulWidget {
  const _AppRatingScreenContent({Key? key}) : super(key: key);

  @override
  State<_AppRatingScreenContent> createState() => _AppRatingScreenContentState();
}

class _AppRatingScreenContentState extends State<_AppRatingScreenContent> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Fetch existing rating and all ratings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppRatingProvider>(context, listen: false);
      provider.fetchMyRating().then((_) {
        if (mounted) {
           final myRating = provider.myRating;
           if (myRating != null) {
             setState(() {
               _rating = myRating.rating;
               if (myRating.comment != null) {
                 _reviewController.text = myRating.comment!;
               }
             });
           }
        }
      });
      // Fetch all ratings
      provider.fetchRatings(refresh: true);
      
      _scrollController.addListener(() {
        if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
          if (provider.hasMore && !provider.isLoading) {
            provider.fetchRatings();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    final provider = Provider.of<AppRatingProvider>(context, listen: false);
    try {
      await provider.submitRating(
        rating: _rating,
        comment: _reviewController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your rating!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit rating: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Consumer<AppRatingProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Rating', 
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, 
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please choose what types of support do you\nneed and let us know.', 
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _rating = index + 1;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Icon(
                            Icons.star_rounded,
                            color: index < _rating ? const Color(0xFFFFC107) : Colors.grey[300],
                            size: 48,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  // Review Field
                  AppRatingScreenTextField(
                    controller: _reviewController,
                    label: 'Write your experience...',
                    maxLines: 6,
                  ),
                  const SizedBox(height: 40),

                  // Done Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Consumer<AppRatingProvider>(
                  builder: (context, provider, child) {
                    // Check if user has already rated
                    final bool alreadyRated = provider.myRating != null;
                    
                    if (alreadyRated) {
                      return ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Update rating coming soon!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C2FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                          fixedSize: const Size(double.infinity, 56),
                        ),
                        child: const Text(
                          'Update Rating',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }

                    return ElevatedButton(
                      onPressed: provider.isLoading 
                          ? null 
                          : () => _submit(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C2FF),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                        fixedSize: const Size(double.infinity, 56), // Ensure consistent size
                      ),
                      child: provider.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    );
                  },
                ),
              ),
                  const SizedBox(height: 40),
                  
                  const SizedBox(height: 20),
                  // Recent Reviews removed

                  // List removed
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class AppRatingScreenTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;

  const AppRatingScreenTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        labelStyle: TextStyle(
          color: Colors.grey[400],
        ),
        floatingLabelStyle: TextStyle(
          color: Colors.grey[400],
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF00C2FF)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      ),
    );
  }
}
