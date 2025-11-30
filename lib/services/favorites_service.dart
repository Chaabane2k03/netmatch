import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get userId => _auth.currentUser?.uid;

  // Collection reference (now a top-level collection)
  CollectionReference get _favoritesCollection =>
      _firestore.collection('favorites');

  // Add movie to favorites
  Future<void> addToFavorites(Map<String, dynamic> movie) async {
    if (userId == null) throw Exception('User not logged in');

    try {
      // Ensure movieId is a string
      final movieId = (movie['id'] ??
          movie['primaryTitle'] ??
          DateTime.now().millisecondsSinceEpoch).toString();

      // Create a unique document ID combining userId and movieId
      final docId = '${userId}_$movieId';

      print('Adding to favorites - User: $userId, MovieId: $movieId'); // Debug

      await _favoritesCollection.doc(docId).set({
        'userId': userId, // Store the user ID
        'movieId': movieId,
        'primaryTitle': movie['primaryTitle'],
        'originalTitle': movie['originalTitle'],
        'releaseDate': movie['releaseDate'],
        'primaryImage': movie['primaryImage'],
        'averageRating': movie['averageRating'],
        'genres': movie['genres'],
        'addedAt': FieldValue.serverTimestamp(),
      });

      print('Successfully added to Firestore'); // Debug
    } catch (e) {
      print('Error adding to favorites: $e');
      rethrow;
    }
  }

  // Remove movie from favorites
  Future<void> removeFromFavorites(String movieId) async {
    if (userId == null) throw Exception('User not logged in');

    try {
      final docId = '${userId}_$movieId';
      await _favoritesCollection.doc(docId).delete();
    } catch (e) {
      print('Error removing from favorites: $e');
      rethrow;
    }
  }

  // Check if movie is in favorites
  Future<bool> isFavorite(String movieId) async {
    if (userId == null) return false;

    try {
      final docId = '${userId}_$movieId';
      final doc = await _favoritesCollection.doc(docId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  // Get all favorites as stream (filtered by current user)
  Stream<List<Map<String, dynamic>>> getFavoritesStream() {
    if (userId == null) return Stream.value([]);

    return _favoritesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    });
  }

  // Get all favorites as future (filtered by current user)
  Future<List<Map<String, dynamic>>> getFavorites() async {
    if (userId == null) return [];

    try {
      final snapshot = await _favoritesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('addedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      print('Error getting favorites: $e');
      return [];
    }
  }

  // Get favorites count
  Future<int> getFavoritesCount() async {
    if (userId == null) return 0;

    try {
      final snapshot = await _favoritesCollection
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting favorites count: $e');
      return 0;
    }
  }
}