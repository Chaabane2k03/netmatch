import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class ManageMoviesPage extends StatefulWidget {
  const ManageMoviesPage({Key? key}) : super(key: key);

  @override
  State<ManageMoviesPage> createState() => _ManageMoviesPageState();
}

class _ManageMoviesPageState extends State<ManageMoviesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Manage Custom Movies',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.red, size: 28),
            onPressed: () => _showAddMovieDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('movies').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorWidget('Error loading movies');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final movies = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['primaryTitle'] ?? '').toString().toLowerCase();
                  final matchesSearch = title.contains(_searchQuery.toLowerCase());

                  if (_selectedFilter == 'All') return matchesSearch;

                  final genres = List<String>.from(data['genres'] ?? []);
                  return matchesSearch && genres.contains(_selectedFilter);
                }).toList();

                if (movies.isEmpty) {
                  return _buildEmptyState(message: 'No movies found');
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    final movieDoc = movies[index];
                    final movie = movieDoc.data() as Map<String, dynamic>;
                    return _buildMovieCard(movieDoc.id, movie);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search movies...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.red),
              filled: true,
              fillColor: Colors.grey[850],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All'),
                _buildFilterChip('Action'),
                _buildFilterChip('Comedy'),
                _buildFilterChip('Drama'),
                _buildFilterChip('Horror'),
                _buildFilterChip('Sci-Fi'),
                _buildFilterChip('Romance'),
                _buildFilterChip('Thriller'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = label);
        },
        backgroundColor: Colors.grey[850],
        selectedColor: Colors.red,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: Colors.white,
      ),
    );
  }

  Widget _buildMovieCard(String movieId, Map<String, dynamic> movie) {
    return GestureDetector(
      onTap: () => _showMovieDetails(movieId, movie),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[900],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      image: movie['primaryImage'] != null
                          ? DecorationImage(
                        image: MemoryImage(base64Decode(movie['primaryImage'])),
                        fit: BoxFit.cover,
                      )
                          : null,
                      color: Colors.grey[800],
                    ),
                    child: movie['primaryImage'] == null
                        ? const Center(
                      child: Icon(Icons.movie, color: Colors.white54, size: 48),
                    )
                        : null,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: PopupMenuButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                      ),
                      color: Colors.grey[900],
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.edit, color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Text('Edit', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                          onTap: () => Future.delayed(
                            Duration.zero,
                                () => _showEditMovieDialog(context, movieId, movie),
                          ),
                        ),
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                          onTap: () => Future.delayed(
                            Duration.zero,
                                () => _confirmDelete(context, movieId, movie['primaryTitle']),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (movie['averageRating'] != null)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              movie['averageRating'].toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie['primaryTitle'] ?? 'No Title',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getYear(movie['releaseDate']),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (movie['genres'] != null && (movie['genres'] as List).isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: (movie['genres'] as List).take(2).map((genre) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red.withOpacity(0.5)),
                          ),
                          child: Text(
                            genre.toString(),
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({String message = 'No custom movies yet'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.movie_creation_outlined, color: Colors.white30, size: 80),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to add your first movie',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddMovieDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Movie'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }

  void _showMovieDetails(String movieId, Map<String, dynamic> movie) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        movie['primaryTitle'] ?? 'No Title',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (movie['primaryImage'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(movie['primaryImage']),
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 300,
                          color: Colors.grey[800],
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                _buildDetailRow('Original Title', movie['originalTitle'] ?? 'N/A'),
                _buildDetailRow('Release Date', movie['releaseDate'] ?? 'N/A'),
                _buildDetailRow('Rating', movie['averageRating']?.toString() ?? 'N/A'),
                _buildDetailRow('Runtime', '${movie['runtimeMinutes'] ?? 'N/A'} min'),
                if (movie['genres'] != null && (movie['genres'] as List).isNotEmpty)
                  _buildDetailRow('Genres', (movie['genres'] as List).join(', ')),
                if (movie['description'] != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Description',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie['description'],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditMovieDialog(context, movieId, movie);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDelete(context, movieId, movie['primaryTitle']);
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMovieDialog(BuildContext context) {
    _showMovieFormDialog(context, isEdit: false);
  }

  void _showEditMovieDialog(BuildContext context, String movieId, Map<String, dynamic> movie) {
    _showMovieFormDialog(context, isEdit: true, movieId: movieId, existingMovie: movie);
  }

  void _showMovieFormDialog(
      BuildContext context, {
        required bool isEdit,
        String? movieId,
        Map<String, dynamic>? existingMovie,
      }) {
    final titleController = TextEditingController(text: existingMovie?['primaryTitle'] ?? '');
    final originalTitleController = TextEditingController(text: existingMovie?['originalTitle'] ?? '');
    final descriptionController = TextEditingController(text: existingMovie?['description'] ?? '');
    final releaseDateController = TextEditingController(text: existingMovie?['releaseDate'] ?? '');
    final ratingController = TextEditingController(text: existingMovie?['averageRating']?.toString() ?? '');
    final runtimeController = TextEditingController(text: existingMovie?['runtimeMinutes']?.toString() ?? '');

    List<String> selectedGenres = List<String>.from(existingMovie?['genres'] ?? []);
    String? base64Image = existingMovie?['primaryImage'];
    XFile? pickedImage;

    // Function to convert image to Base64 with compression
    Future<String?> _imageToBase64(XFile imageFile) async {
      try {
        final bytes = await imageFile.readAsBytes();

        // Decode the image
        final image = img.decodeImage(bytes);
        if (image == null) {
          return base64Encode(bytes);
        }

        // Resize to max 800px width while maintaining aspect ratio
        final resized = img.copyResize(image, width: 800);

        // Encode as JPEG with 80% quality for compression
        final compressedBytes = img.encodeJpg(resized, quality: 80);

        // Check size (Firestore has 1MB limit, so we aim for less)
        if (compressedBytes.length > 900 * 1024) { // 900KB
          // If still too large, resize more aggressively
          final smaller = img.copyResize(image, width: 400);
          final moreCompressed = img.encodeJpg(smaller, quality: 60);
          return base64Encode(moreCompressed);
        }

        return base64Encode(compressedBytes);
      } catch (e) {
        print('Error converting image to Base64: $e');
        return null;
      }
    }

    // Function to get image widget from XFile
    Future<Widget> _getImageWidget(XFile imageFile) async {
      try {
        final bytes = await imageFile.readAsBytes();
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
          ),
        );
      } catch (e) {
        return const Center(
          child: Icon(Icons.error, color: Colors.red),
        );
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isEdit ? 'Edit Movie' : 'Add New Movie',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Image picker
                  GestureDetector(
                    onTap: () async {
                      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setDialogState(() {
                          pickedImage = image;
                          base64Image = null; // Clear existing Base64 when new image picked
                        });
                      }
                    },
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: pickedImage != null
                          ? FutureBuilder<Widget>(
                        future: _getImageWidget(pickedImage!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(color: Colors.red),
                            );
                          }
                          return snapshot.data ??
                              const Center(
                                child: Icon(Icons.error, color: Colors.red),
                              );
                        },
                      )
                          : base64Image != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(base64Image!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                            );
                          },
                        ),
                      )
                          : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, color: Colors.white54, size: 48),
                          SizedBox(height: 8),
                          Text(
                            'Tap to add poster image',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  _buildTextField(titleController, 'Title *', Icons.movie),
                  const SizedBox(height: 12),
                  _buildTextField(originalTitleController, 'Original Title', Icons.title),
                  const SizedBox(height: 12),
                  _buildTextField(descriptionController, 'Description', Icons.description, maxLines: 4),
                  const SizedBox(height: 12),
                  _buildTextField(releaseDateController, 'Release Date (YYYY-MM-DD)', Icons.calendar_today),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(ratingController, 'Rating (0-10)', Icons.star, keyboardType: TextInputType.number),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(runtimeController, 'Runtime (min)', Icons.access_time, keyboardType: TextInputType.number),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Genres',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'Action', 'Comedy', 'Drama', 'Horror', 'Sci-Fi',
                      'Romance', 'Thriller', 'Animation', 'Documentary', 'Fantasy'
                    ].map((genre) {
                      final isSelected = selectedGenres.contains(genre);
                      return FilterChip(
                        label: Text(genre),
                        selected: isSelected,
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedGenres.add(genre);
                            } else {
                              selectedGenres.remove(genre);
                            }
                          });
                        },
                        backgroundColor: Colors.grey[850],
                        selectedColor: Colors.red,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        checkmarkColor: Colors.white,
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Title is required'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        try {
                          String? finalBase64Image = base64Image;

                          // Convert new image to Base64 if picked
                          if (pickedImage != null) {
                            finalBase64Image = await _imageToBase64(pickedImage!);

                            // Check image size (Base64 increases size by ~33%)
                            if (finalBase64Image != null && finalBase64Image.length > 1.2 * 1024 * 1024) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Image too large. Please choose a smaller image.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                          }

                          final movieData = {
                            'primaryTitle': titleController.text,
                            'originalTitle': originalTitleController.text.isEmpty ? titleController.text : originalTitleController.text,
                            'description': descriptionController.text,
                            'releaseDate': releaseDateController.text,
                            'averageRating': double.tryParse(ratingController.text),
                            'runtimeMinutes': int.tryParse(runtimeController.text),
                            'genres': selectedGenres,
                            'primaryImage': finalBase64Image,
                            'updatedAt': FieldValue.serverTimestamp(),
                          };

                          if (isEdit && movieId != null) {
                            await _firestore.collection('movies').doc(movieId).update(movieData);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Movie updated successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            movieData['createdAt'] = FieldValue.serverTimestamp();
                            await _firestore.collection('movies').add(movieData);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Movie added successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }

                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isEdit ? 'Update Movie' : 'Add Movie',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.red),
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String movieId, String? title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Movie',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${title ?? 'this movie'}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('movies').doc(movieId).delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Movie deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting movie: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getYear(String? date) {
    if (date == null || date.isEmpty) return 'N/A';
    try {
      return date.split('-')[0];
    } catch (e) {
      return 'N/A';
    }
  }
}