import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/app_rating_provider.dart';

class AppRatingDialog extends StatelessWidget {
  const AppRatingDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppRatingProvider.create(),
      child: const _AppRatingDialogContent(),
    );
  }
}

class _AppRatingDialogContent extends StatefulWidget {
  const _AppRatingDialogContent({Key? key}) : super(key: key);

  @override
  State<_AppRatingDialogContent> createState() => _AppRatingDialogContentState();
}

class _AppRatingDialogContentState extends State<_AppRatingDialogContent> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch existing rating if any
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppRatingProvider>(context, listen: false);
      provider.fetchMyRating().then((_) {
        if (mounted) {
           final myRating = provider.myRating;
           if (myRating != null) {
             setState(() {
               _rating = myRating.rating;
               _commentController.text = myRating.comment ?? '';
             });
           }
        }
      });
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
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
    final isUpdate = provider.myRating != null;
    
    try {
      if (isUpdate) {
        await provider.updateRating(
          rating: _rating,
          comment: _commentController.text.trim(),
        );
      } else {
        await provider.submitRating(
          rating: _rating,
          comment: _commentController.text.trim(),
        );
      }
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(isUpdate ? 'Rating updated successfully!' : 'Thank you for your rating!')),
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
    // Access provider via Consumer or Provider.of to react to changes
    return Consumer<AppRatingProvider>(
      builder: (context, provider, child) {
        final isUpdate = provider.myRating != null;
        
        return AlertDialog(
          title: Text(isUpdate ? 'Update Your Rating' : 'Rate Our App'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('How was your experience?'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          _rating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Leave a comment (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: provider.isLoading ? null : () => _submit(context),
              child: provider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isUpdate ? 'Update' : 'Submit'),
            ),
          ],
        );
      },
    );
  }
}
