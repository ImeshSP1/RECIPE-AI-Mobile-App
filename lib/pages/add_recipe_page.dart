// add_recipe_page.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddRecipePage extends StatefulWidget {
  const AddRecipePage({super.key});

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _cookingTimeController = TextEditingController();
  final _imageUrlController = TextEditingController();

  List<File> _selectedImages = [];
  final picker = ImagePicker();
  bool _isSubmitting = false;

  List<TextEditingController> _stepControllers = [TextEditingController()];
  final List<String> _categories = ['Breakfast', 'Lunch', 'Dinner', 'Dessert', 'Snack'];
  String _selectedCategory = '';

  // Draft state
  bool _isDraftSaved = false;

  /// Pick up to 3 images from gallery
  Future<void> _pickImages() async {
    final picked = await picker.pickMultiImage(imageQuality: 75);
    if (picked != null) {
      setState(() {
        _selectedImages = picked.map((x) => File(x.path)).take(3).toList();
      });
    }
  }

  /// Upload chosen images to Firebase Storage and return their URLs
  Future<List<String>> _uploadImages(User user) async {
    List<String> urls = [];
    for (int i = 0; i < _selectedImages.length; i++) {
      final img = _selectedImages[i];
      final path = 'recipes/${user.uid}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final ref = FirebaseStorage.instance.ref().child(path);
      await ref.putFile(img);
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  /// Submit recipe to Firestore
  Future<void> _submitRecipe(User user) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }
    if (_selectedImages.isEmpty && _imageUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }
    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await user.reload();
      final refreshed = FirebaseAuth.instance.currentUser!;

      // Build image URLs list
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages(refreshed);
      } else {
        imageUrls = [_imageUrlController.text.trim()];
      }

      final steps = _stepControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();

      await FirebaseFirestore.instance.collection('recipelist').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'ingredients': _ingredientsController.text.trim(),
        'steps': steps,
        'cookingTime': _cookingTimeController.text.trim(),
        'imageUrls': imageUrls,
        'authorName': refreshed.displayName ?? 'Anonymous',
        'authorEmail': refreshed.email,
        'authorId': refreshed.uid,
        'timestamp': Timestamp.now(),
      });

      // Clear all fields after post
      _formKey.currentState!.reset();
      _imageUrlController.clear();
      setState(() {
        _selectedImages.clear();
        _selectedCategory = '';
        _stepControllers = [TextEditingController()];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe posted successfully!')),
      );
    } catch (e) {
      print('Submit error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => _isSubmitting = false);
  }

  /// Save a draft (local only)
  void _saveDraft() {
    _isDraftSaved = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved locally')),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    _cookingTimeController.dispose();
    _imageUrlController.dispose();
    for (var c in _stepControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, snapshot) {
        final user = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (user == null) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                child: const Text('Login to Post Recipe'),
                onPressed: () => Navigator.of(context).pushNamed('/login'),
              ),
            ),
          );
        }

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
        Icon(Icons.edit, color: Colors.white, size: 28),
        SizedBox(width: 10),
        Text(
          'Add New Recipe',
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

          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(children: [
                // Images
                GestureDetector(
                  onTap: _pickImages,
                  child: _selectedImages.isNotEmpty
                      ? SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            itemBuilder: (_, i) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_selectedImages[i], width: 120, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(child: Text("Tap to select images")),
                        ),
                ),
                const SizedBox(height: 10),
                // URL Image form & preview
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'Or enter image URL', border: OutlineInputBorder()),
                  keyboardType: TextInputType.url,
                  onChanged: (_) => setState(() {}),
                ),
                if (_imageUrlController.text.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(_imageUrlController.text.trim(), height: 150, fit: BoxFit.cover),
                    ),
                  ),
                const SizedBox(height: 10),

                // Text inputs
                _buildTextField(_titleController, 'Title'),
                _buildTextField(_descriptionController, 'Description', maxLines: 3),
                _buildTextField(_ingredientsController, 'Ingredients (comma-separated)', maxLines: 2),
                _buildTextField(_cookingTimeController, 'Cooking Time (e.g. 30 mins)'),

                // Category chips
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: _categories.map((cat) {
                    return ChoiceChip(
                      label: Text(cat),
                      selected: _selectedCategory == cat,
                      selectedColor: Colors.green.shade300,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    );
                  }).toList(),
                ),

                // Step fields
                const SizedBox(height: 20),
                Column(
                  children: List.generate(_stepControllers.length, (idx) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        Expanded(
                          child: TextFormField(
                            controller: _stepControllers[idx],
                            decoration:
                                InputDecoration(labelText: 'Step ${idx + 1}', border: const OutlineInputBorder()),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Step ${idx + 1} is required' : null,
                          ),
                        ),
                        if (_stepControllers.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => setState(() => _stepControllers.removeAt(idx)),
                          ),
                      ]),
                    );
                  }),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _stepControllers.add(TextEditingController())),
                  icon: const Icon(Icons.add),
                  label: const Text("Add Step"),
                ),

                const SizedBox(height: 20),
                // Post button with icon
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : () => _submitRecipe(user),
                  icon: const Icon(Icons.cloud_upload, color: Colors.white),
                  label: const Text('Post Recipe', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }

  // Helper for input fields
  Widget _buildTextField(TextEditingController ctl, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: ctl,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (v) => v == null || v.trim().isEmpty ? '$label is required' : null,
      ),
    );
  }
}
