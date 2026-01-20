import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecipeFeedPage extends StatefulWidget {
  const RecipeFeedPage({super.key});

  @override
  State<RecipeFeedPage> createState() => _RecipeFeedPageState();
}

class _RecipeFeedPageState extends State<RecipeFeedPage> {
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter recipes based on search input
  bool _matchesSearch(Map<String, dynamic> data) {
    final title = (data['title'] ?? '').toString().toLowerCase();
    final authorName = (data['authorName'] ?? '').toString().toLowerCase();
    final query = _searchQuery.toLowerCase();
    return title.contains(query) || authorName.contains(query);
  }

  // Like/unlike functionality
  Future<void> _toggleLike(String recipeId, List<dynamic> currentLikes) async {
    final userId = user?.uid;
    if (userId == null) return;

    final likes = List<String>.from(currentLikes.map((e) => e.toString()));
    final docRef = FirebaseFirestore.instance.collection('recipelist').doc(recipeId);

    if (likes.contains(userId)) {
      likes.remove(userId);
    } else {
      likes.add(userId);
    }

    await docRef.update({'likes': likes});
  }

  // Save/unsave functionality
  Future<void> _toggleSave(String recipeId, List<dynamic> currentSavedBy) async {
    final userId = user?.uid;
    if (userId == null) return;

    final savedBy = List<String>.from(currentSavedBy.map((e) => e.toString()));
    final docRef = FirebaseFirestore.instance.collection('recipelist').doc(recipeId);

    if (savedBy.contains(userId)) {
      savedBy.remove(userId);
    } else {
      savedBy.add(userId);
    }

    await docRef.update({'savedBy': savedBy});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
          ),
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.home_filled, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text(
                'Home',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search recipes or authors...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim();
                  });
                },
              ),
            ),
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('recipelist')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong. Please try again.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final recipes = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _searchQuery.isEmpty || _matchesSearch(data);
          }).toList();

          if (recipes.isEmpty) {
            return const Center(child: Text('No recipes found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              final data = recipe.data() as Map<String, dynamic>;

              final title = data['title'] ?? 'No Title';
              final description = data['description'] ?? '';
              final imageUrl = data['imageUrl'] ?? '';
              final authorName = data['authorName'] ?? 'Unknown';
              final authorImage = data['authorImage'] ?? '';
              final timestamp = data['timestamp'] as Timestamp?;
              final postTime = timestamp != null
                  ? DateFormat.yMMMd().add_jm().format(timestamp.toDate())
                  : '';

              final likes = data['likes'] ?? [];
              final savedBy = data['savedBy'] ?? [];

              final isLiked = user != null && likes.contains(user!.uid);
              final isSaved = user != null && savedBy.contains(user!.uid);

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  // REMOVE ONTAP: No navigation to detail page
                  onTap: () {},

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recipe Image
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: const Center(child: CircularProgressIndicator()),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image,
                                        size: 60, color: Colors.grey),
                                  );
                                },
                              )
                            : Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported,
                                    size: 50, color: Colors.grey),
                              ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Recipe Title
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Author info & date
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: authorImage.isNotEmpty
                                      ? NetworkImage(authorImage)
                                      : null,
                                  backgroundColor: Colors.green[200],
                                  child: authorImage.isEmpty
                                      ? const Icon(Icons.person, size: 18)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  authorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  postTime,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Description preview
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),

                            const SizedBox(height: 10),

                            // Like & Save buttons
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: isLiked ? Colors.red : Colors.grey[700],
                                  ),
                                  onPressed: () {
                                    _toggleLike(recipe.id, likes);
                                  },
                                ),
                                Text('${likes.length}'),

                                const SizedBox(width: 24),

                                IconButton(
                                  icon: Icon(
                                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                                    color: isSaved ? Colors.blue[700] : Colors.grey[700],
                                  ),
                                  onPressed: () {
                                    _toggleSave(recipe.id, savedBy);
                                  },
                                ),
                                Text('${savedBy.length}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
