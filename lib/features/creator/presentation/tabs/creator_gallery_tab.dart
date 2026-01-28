// tabs/gallery_tab.dart
import 'package:flutter/material.dart';

class CreatorGalleryTab extends StatefulWidget {
  @override
  _CreatorGalleryTabState createState() => _CreatorGalleryTabState();
}

class _CreatorGalleryTabState extends State<CreatorGalleryTab> {
  String selectedTab = 'Post';

  @override
  Widget build(BuildContext context) {
    // Dummy image data
    final List<String> imageUrls = [
      'https://images.unsplash.com/photo-1533929736458-ca588d08c8be?q=80&w=400', // Mining/cave worker
      'https://images.unsplash.com/photo-1454496522488-7a8e488e8606?q=80&w=400', // Mountains
      'https://images.unsplash.com/photo-1580489944761-15a19d654956?q=80&w=400', // Woman with coffee
      'https://images.unsplash.com/photo-1520962880247-cfaf541c8724?q=80&w=400', // Pine forest
      'https://images.unsplash.com/photo-1543466835-00a7907e9de1?q=80&w=400', // Black dog
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=400', // Man portrait
      'https://images.unsplash.com/photo-1569230516306-5a8cb5586399?q=80&w=400', // Ferris wheel
      'https://images.unsplash.com/photo-1502730696376-43b3d8020703?q=80&w=400', // Sunset
      'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=400', // Concert lights
      'https://images.unsplash.com/photo-1511317559916-56d5ddb62563?q=80&w=400', // Man in stripe shirt
      'https://images.unsplash.com/photo-1516383607781-4d6c28a600fa?q=80&w=400', // Man in blue
      'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=400', // Two dogs
      'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?q=80&w=400', // Pug
      'https://images.unsplash.com/photo-1587300003388-59208cc962cb?q=80&w=400', // Puppy
      'https://images.unsplash.com/photo-1561948955-570b270e7c36?q=80&w=400',
    ];

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(child: _buildTabButton('Post', selectedTab == 'Post')),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildTabButton('Videos', selectedTab == 'Videos')),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String title, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
