import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeDetailPage extends StatefulWidget {
  final int recipeId;

  const RecipeDetailPage({
    Key? key,
    required this.recipeId, required String apiKey, required Map<String, dynamic> recipeData, required String ,
  }) : super(key: key);

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  final String apiKey = '68a99f68733b4160a3bdb6d9344a38e3';

  Map<String, dynamic>? recipe;
  bool loading = true;
  bool isSaved = false;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    currentUser = FirebaseAuth.instance.currentUser;
    await fetchRecipeDetails();
    if (currentUser != null) {
      await checkIfSaved();
    }
  }

  Future<void> fetchRecipeDetails() async {
    setState(() => loading = true);
    final url = Uri.parse(
      'https://api.spoonacular.com/recipes/${widget.recipeId}/information?includeNutrition=false&apiKey=$apiKey',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      setState(() {
        recipe = json.decode(response.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load recipe details.')),
        );
      }
    }
  }

  Future<void> checkIfSaved() async {
    if (currentUser == null || recipe == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('favorites')
        .doc(widget.recipeId.toString())
        .get();

    if (mounted) {
      setState(() {
        isSaved = doc.exists;
      });
    }
  }

  Future<void> _toggleSave() async {
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save recipes.')),
      );
      return;
    }

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('favorites')
        .doc(widget.recipeId.toString());

    if (isSaved) {
      await docRef.delete();
      if (mounted) {
        setState(() => isSaved = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from Favorites')),
        );
      }
    } else {
      await docRef.set({
        'id': widget.recipeId,
        'title': recipe!['title'],
        'image': recipe!['image'],
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        setState(() => isSaved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to Favorites!')),
        );
      }
    }
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Details'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : recipe == null
              ? const Center(child: Text('No details found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe!['title'],
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(recipe!['image'] ?? ''),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("⏱ ${recipe!['readyInMinutes']} min"),
                          Text("🍽 Servings: ${recipe!['servings']}"),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _stripHtml(recipe!['summary'] ?? ''),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      const Text("🧂 Ingredients:",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...List.generate(
                        recipe!['extendedIngredients'].length,
                        (i) => Text(
                            '• ${recipe!['extendedIngredients'][i]['original']}'),
                      ),
                      const SizedBox(height: 20),
                      const Text("👨‍🍳 Instructions:",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      recipe!['analyzedInstructions'] != null &&
                              recipe!['analyzedInstructions'].isNotEmpty
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(
                                recipe!['analyzedInstructions'][0]['steps']
                                    .length,
                                (index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                      '${index + 1}. ${recipe!['analyzedInstructions'][0]['steps'][index]['step']}'),
                                ),
                              ),
                            )
                          : const Text('No steps available.'),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(
                              isSaved ? Icons.favorite : Icons.favorite_border,
                              color: Colors.white,
                            ),
                            onPressed: _toggleSave,
                            label: Text(isSaved ? "Saved" : "Save"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isSaved ? Colors.redAccent : Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.share, color: Colors.white),
                            onPressed: () {
                              // TODO: Implement share feature
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Posted to Wall!')),
                              );
                            },
                            label: const Text("Share"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
    );
  }
}
