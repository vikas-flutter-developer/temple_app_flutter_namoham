import 'package:flutter/material.dart';
import 'package:flutter_user_app/features/temples/data/models/review_model.dart';
import 'package:flutter_user_app/features/temples/data/models/temple_model.dart';
import 'package:flutter_user_app/features/temples/presentation/widgets/review_dropdown_widget.dart';

class ReviewTab extends StatefulWidget {
  final List<ReviewModel> reviews;
  final TempleModel temple;

  const ReviewTab({
    Key? key,
    required this.reviews,
    required this.temple,
  }) : super(key: key);

  @override
  State<ReviewTab> createState() => _ReviewTabState();
}

class _ReviewTabState extends State<ReviewTab> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate percentage for each star rating
    Map<int, int> ratingCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    // Count reviews for each star rating
    for (var review in widget.reviews) {
      int rating = review.rating.round();
      if (ratingCounts.containsKey(rating)) {
        ratingCounts[rating] = ratingCounts[rating]! + 1;
      }
    }

    // Calculate percentages
    Map<int, double> ratingPercentages = {};
    for (var entry in ratingCounts.entries) {
      ratingPercentages[entry.key] =
          widget.reviews.isEmpty ? 0 : entry.value / widget.reviews.length;
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating Summary
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side: Rating bars
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRatingBar(5, ratingPercentages[5] ?? 0),
                      _buildRatingBar(4, ratingPercentages[4] ?? 0),
                      _buildRatingBar(3, ratingPercentages[3] ?? 0),
                      _buildRatingBar(2, ratingPercentages[2] ?? 0),
                      _buildRatingBar(1, ratingPercentages[1] ?? 0),
                    ],
                  ),
                ),

                // Right side: Average rating and recommendation
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.temple.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.star, color: Colors.amber, size: 24),
                        ],
                      ),
                      Text(
                        "${widget.temple.totalReviews} Reviews",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "${widget.temple.recommendationPercentage}%",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Recommended",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),

            // Reviews Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reviews',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ReviewDropDownWidget(),
              ],
            ),

            SizedBox(height: 8),

            // Review List
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: widget.reviews.length,
              //separatorBuilder: (context, index) => Divider(),
              itemBuilder: (context, index) {
                final review = widget.reviews[index];
                return _buildReviewItem(review);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(int stars, double percentage) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$stars',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  stars >= 4
                      ? theme.colorScheme.primary
                      : stars >= 3
                          ? theme.colorScheme.primary.withOpacity(0.7)
                          : theme.colorScheme.outline,
                ),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(ReviewModel review) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: review.profileImageUrl != null
                      ? NetworkImage(review.profileImageUrl!)
                      : null,
                  child: review.profileImageUrl == null
                      ? Icon(Icons.person)
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating.floor()
                                ? Icons.star
                                : i < review.rating
                                    ? Icons.star_half
                                    : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(review.comment),
            SizedBox(height: 8),
            Row(
              children: [
                Row(
                  children: [
                    Icon(Icons.thumb_up_outlined,
                        size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text('${review.likes}',
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
                SizedBox(width: 16),
                Row(
                  children: [
                    Icon(Icons.thumb_down_outlined,
                        size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text('${review.dislikes}',
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
