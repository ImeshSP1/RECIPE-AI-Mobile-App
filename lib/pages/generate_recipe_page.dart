import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'recipe_details_page.dart';

class GenerateRecipePage extends StatefulWidget {
  const GenerateRecipePage({Key? key}) : super(key: key);

  @override
  State<GenerateRecipePage> createState() => _GenerateRecipePageState();
}

class _GenerateRecipePageState extends State<GenerateRecipePage> {
  final TextEditingController _ingredientController = TextEditingController();
  final String apiKey =
      '68a99f68733b4160a3bdb6d9344a38e3'; // Replace with your API key

  bool _loading = false;
  List<dynamic> _recipes = [];

  /// Fetch recipes from Spoonacular API using given ingredients
  Future<void> _fetchRecipes(String ingredients) async {
    if (ingredients.trim().isEmpty) return;

    setState(() {
      _loading = true;
      _recipes = [];
    });

    try {
      final url = Uri.parse(
        'https://api.spoonacular.com/recipes/findByIngredients'
        '?ingredients=${Uri.encodeComponent(ingredients)}&number=100&apiKey=$apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => _recipes = data);
      } else {
        _showError('Failed to fetch recipes: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Open camera and identify ingredients using ML Kit
  Future<void> _openCamera() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.camera);
    if (pickedImage == null) return;

    final inputImage = InputImage.fromFile(File(pickedImage.path));
    final imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.6),
    );

    final labels = await imageLabeler.processImage(inputImage);
    imageLabeler.close();

    if (labels.isEmpty) {
      _showError('No ingredients detected');
    } else {
      final ingredients = labels.map((l) => l.label).toSet().join(', ');
      setState(() {
        _ingredientController.text = ingredients;
      });
      _fetchRecipes(ingredients);
    }
  }

  /// Show error message in Snackbar
  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Navigate to recipe detail page
  void _showRecipeDetails(int recipeId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => RecipeDetailPage(recipeId: recipeId, apiKey: apiKey, recipeData: {}, String: null,),
      ),
    );
  }

  /// Main UI build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
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
              Icon(Icons.auto_awesome, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text(
                'Smart Recipe Generator',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),

      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F5E9), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input field and camera button
            Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ingredientController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. tomato, cheese, basil...',
                          border: InputBorder.none,
                          labelText: 'Enter Ingredients',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      color: const Color(0xFF4CAF50),
                      onPressed: _openCamera,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Generate Recipes Button
            Center(
              child: GestureDetector(
                onTap:
                    _loading
                        ? null
                        : () => _fetchRecipes(_ingredientController.text),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.restaurant_menu,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Generate',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Displaying recipes
            Expanded(
              child:
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _recipes.isEmpty
                      ? const Center(child: Text('No recipes found yet.'))
                      : ListView.builder(
                        itemCount: _recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = _recipes[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  recipe['image'] ?? '',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(
                                recipe['title'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                'Used: ${recipe['usedIngredientCount']}  •  Missed: ${recipe['missedIngredientCount']}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              onTap: () => _showRecipeDetails(recipe['id']),
                            ),
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
