import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get userId => _auth.currentUser?.uid;

  // Collection reference
  CollectionReference get _favoritesCollection =>
      _firestore.collection('users').doc(userId).collection('favorites');

  // Add movie to favorites
  Future<void> addToFavorites(Map<String, dynamic> movie) async {
    if (userId == null) throw Exception('User not logged in');

    try {
      final movieId = movie['id'] ?? movie['primaryTitle'] ?? DateTime.now().millisecondsSinceEpoch.toString();

      await _favoritesCollection.doc(movieId).set({
        'id': movieId,
        'primaryTitle': movie['primaryTitle'],
        'originalTitle': movie['originalTitle'],
        'releaseDate': movie['releaseDate'],
        'primaryImage': movie['primaryImage'],
        'averageRating': movie['averageRating'],
        'genres': movie['genres'],
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding to favorites: $e');
      rethrow;
    }
  }

  // Remove movie from favorites
  Future<void> removeFromFavorites(String movieId) async {
    if (userId == null) throw Exception('User not logged in');

    try {
      await _favoritesCollection.doc(movieId).delete();
    } catch (e) {
      print('Error removing from favorites: $e');
      rethrow;
    }
  }

  // Check if movie is in favorites
  Future<bool> isFavorite(String movieId) async {
    if (userId == null) return false;

    try {
      final doc = await _favoritesCollection.doc(movieId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  // Get all favorites as stream
  Stream<List<Map<String, dynamic>>> getFavoritesStream() {
    if (userId == null) return Stream.value([]);

    return _favoritesCollection
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    });
  }

  // Get all favorites as future
  Future<List<Map<String, dynamic>>> getFavorites() async {
    if (userId == null) return [];

    try {
      final snapshot = await _favoritesCollection
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
      final snapshot = await _favoritesCollection.get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting favorites count: $e');
      return 0;
    }
  }
}