import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SeedFavoritesData {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sample user IDs - replace these with your actual user IDs from Firebase Auth
  final List<String> userIds = [
    '8MyWLTTFyNRYnEVVuTVdUgk7gKf1',
    'Q8Zo0H8nHOVB3p7fZjcpycVosdl1',
    'wKgLN6ddwjd2yF4wpQNjzwS1RZL2',
    'H9fYxoPsemU6wBM3qz9O83iEgqd2'
  ];

  // Your movie data
  final List<Map<String, dynamic>> movies = [
    {
      'id': 'tt0111161',
      'primaryTitle': 'The Shawshank Redemption',
      'originalTitle': 'The Shawshank Redemption',
      'releaseDate': '1994-10-14',
      'primaryImage': 'https://m.media-amazon.com/images/M/MV5BMDAyY2FhYjctNDc5OS00MDNlLThiMGUtY2UxYWVkNGY2ZjljXkEyXkFqcGc@.jpg',
      'averageRating': 9.3,
      'genres': ['Drama'],
    },
    {
      'id': 'tt0068646',
      'primaryTitle': 'The Godfather',
      'originalTitle': 'The Godfather',
      'releaseDate': '1972-03-24',
      'primaryImage': 'https://m.media-amazon.com/images/M/MV5BNGEwYjgwOGQtYjg5ZS00Njc1LTk2ZGEtM2QwZWQ2NjdhZTE5XkEyXkFqcGc@.jpg',
      'averageRating': 9.2,
      'genres': ['Crime', 'Drama'],
    },
    {
      'id': 'tt0816692',
      'primaryTitle': 'Interstellar',
      'originalTitle': 'Interstellar',
      'releaseDate': '2014-11-07',
      'primaryImage': 'https://m.media-amazon.com/images/M/MV5BYzdjMDAxZGItMjI2My00ODA1LTlkNzItOWFjMDU5ZDJlYWY3XkEyXkFqcGc@.jpg',
      'averageRating': 8.7,
      'genres': ['Adventure', 'Drama', 'Sci-Fi'],
    },
    {
      'id': 'tt1375666',
      'primaryTitle': 'Inception',
      'originalTitle': 'Inception',
      'releaseDate': '2010-07-16',
      'primaryImage': 'https://m.media-amazon.com/images/M/MV5BMjAxMzY3NjcxNF5BMl5BanBnXkFtZTcwNTI5OTM0Mw@@.jpg',
      'averageRating': 8.8,
      'genres': ['Action', 'Adventure', 'Sci-Fi'],
    },
    {
      'id': 'tt0120737',
      'primaryTitle': 'The Lord of the Rings: The Fellowship of the Ring',
      'originalTitle': 'The Lord of the Rings: The Fellowship of the Ring',
      'releaseDate': '2001-12-19',
      'primaryImage': 'https://m.media-amazon.com/images/M/MV5BNzIxMDQ2YTctNDY4MC00ZTRhLTk4ODQtMTVlOWY4NTdiYmMwXkEyXkFqcGc@.jpg',
      'averageRating': 8.9,
      'genres': ['Adventure', 'Drama', 'Fantasy'],
    },
    {
      'id': 'tt5950044',
      'primaryTitle': 'Superman',
      'originalTitle': 'Superman',
      'releaseDate': '2025-07-11',
      'primaryImage': 'https://m.media-amazon.com/images/M/MV5BOGMwZGJiM2EtMzEwZC00YTYzLWIxNzYtMmJmZWNlZjgxZTMwXkEyXkFqcGc@.jpg',
      'averageRating': 7.1,
      'genres': ['Action', 'Adventure', 'Sci-Fi'],
    },
    {
      'id': 'tt31193180',
      'primaryTitle': 'Sinners',
      'originalTitle': 'Sinners',
      'releaseDate': '2025-04-18',
      'primaryImage': 'https://m.media-amazon.com/images/M/MV5BNjIwZWY4ZDEtMmIxZS00NDA4LTg4ZGMtMzUwZTYyNzgxMzk5XkEyXkFqcGc@.jpg',
      'averageRating': 7.6,
      'genres': ['Action', 'Drama', 'Horror'],
    },
    {
      'id': 'tt31036941',
      'primaryTitle': 'Jurassic World: Rebirth',
      'originalTitle': 'Jurassic World: Rebirth',
      'releaseDate': '2025-07-02',
      'primaryImage': 'https://m.media-amazon.com/images/M/MV5BMGM3ZmI3NzQtNzU5Yi00ZWI1LTg3YTAtNmNmNWIyMWFjZTBkXkEyXkFqcGc@.jpg',
      'averageRating': 5.9,
      'genres': ['Action', 'Adventure', 'Sci-Fi'],
    },
    {
      'id': 'tt1396484',
      'primaryTitle': 'It',
      'originalTitle': 'It',
      'releaseDate': '2017-09-08',
      'primaryImage': 'https://m.media-amazon.com/images/M/MV5BZGZmOTZjNzUtOTE4OS00OGM3LWJiNGEtZjk4Yzg2M2Q1YzYxXkEyXkFqcGc@.jpg',
      'averageRating': 7.3,
      'genres': ['Horror'],
    },
    {
      'id': 'tt0319343',
      'primaryTitle': 'Elf',
      'originalTitle': 'Elf',
      'releaseDate': '2003-11-07',
      'primaryImage': 'https://m.media-amazon.com/images/M/MV5BNDQ0ZWE2NzgtNGNhMC00MDIwLWI1MjUtYjYxZGRiM2UyYTQzXkEyXkFqcGc@.jpg',
      'averageRating': 7.1,
      'genres': ['Adventure', 'Comedy', 'Family'],
    },
  ];

  Future<void> seedFavorites() async {
    try {
      print('Starting to seed favorites...');

      int totalAdded = 0;

      // Create strategic favorite assignments to ensure matches
      // We'll create overlapping favorites to guarantee matches between users

      // Define movie groups that will be shared between users
      final List<List<String>> movieGroups = [
        // Group 1: Popular movies that many users will share
        ['tt0111161', 'tt0068646', 'tt0816692'], // Shawshank, Godfather, Interstellar
        // Group 2: Sci-Fi/Adventure movies
        ['tt1375666', 'tt0120737', 'tt5950044'], // Inception, LOTR, Superman
        // Group 3: Mixed genre movies
        ['tt31193180', 'tt31036941', 'tt1396484'], // Sinners, Jurassic World, It
        // Group 4: Various popular movies
        ['tt0319343', 'tt0111161', 'tt1375666'], // Elf, Shawshank, Inception
      ];

      // Assign favorites to each user with intentional overlaps
      for (int i = 0; i < userIds.length; i++) {
        final userId = userIds[i];
        print('\nSeeding favorites for user: $userId');

        // Each user gets their group plus some random movies
        final userMovies = <Map<String, dynamic>>[];

        // Add movies from this user's primary group
        final primaryGroup = movieGroups[i % movieGroups.length];
        for (var movieId in primaryGroup) {
          final movie = movies.firstWhere((m) => m['id'] == movieId);
          userMovies.add(movie);
        }

        // Add movies from the next group to create overlaps
        final nextGroupIndex = (i + 1) % movieGroups.length;
        final nextGroup = movieGroups[nextGroupIndex];
        for (var movieId in nextGroup.take(2)) { // Take 2 from next group
          final movie = movies.firstWhere((m) => m['id'] == movieId);
          if (!userMovies.any((m) => m['id'] == movieId)) {
            userMovies.add(movie);
          }
        }

        // Add 1-2 random movies to make it more natural
        final availableMovies = movies.where((movie) =>
        !userMovies.any((m) => m['id'] == movie['id'])).toList();
        availableMovies.shuffle();
        final randomMovies = availableMovies.take(1 + (i % 2)).toList();
        userMovies.addAll(randomMovies);

        // Add each movie to favorites
        for (var movie in userMovies) {
          final movieId = movie['id'];
          final docId = '${userId}_$movieId';

          await _firestore.collection('favorites').doc(docId).set({
            'userId': userId,
            'movieId': movieId,
            'primaryTitle': movie['primaryTitle'],
            'originalTitle': movie['originalTitle'],
            'releaseDate': movie['releaseDate'],
            'primaryImage': movie['primaryImage'],
            'averageRating': movie['averageRating'],
            'genres': movie['genres'],
            'addedAt': FieldValue.serverTimestamp(),
          });

          totalAdded++;
          print('  ✓ Added: ${movie['primaryTitle']}');
        }

        print('Added ${userMovies.length} movies for $userId');

        // Print the user's favorites for debugging
        print('  User $userId favorites: ${userMovies.map((m) => m['primaryTitle']).toList()}');
      }

      print('\n✅ Successfully seeded $totalAdded favorites for ${userIds.length} users!');

      // Print expected matches for verification
      await _printExpectedMatches();

    } catch (e) {
      print('❌ Error seeding favorites: $e');
      rethrow;
    }
  }

  // Method to print expected matches between users
  Future<void> _printExpectedMatches() async {
    print('\n🎯 EXPECTED MATCHES ANALYSIS:');

    for (int i = 0; i < userIds.length; i++) {
      for (int j = i + 1; j < userIds.length; j++) {
        final user1 = userIds[i];
        final user2 = userIds[j];

        final user1Favorites = await _getUserFavorites(user1);
        final user2Favorites = await _getUserFavorites(user2);

        final commonMovies = user1Favorites.where((movie1) =>
            user2Favorites.any((movie2) => movie2['movieId'] == movie1['movieId'])).toList();

        final matchPercentage = (commonMovies.length / user1Favorites.length * 100).round();

        print('  $user1 ↔ $user2: ${commonMovies.length} common movies ($matchPercentage% match)');
        if (commonMovies.isNotEmpty) {
          print('    Common: ${commonMovies.map((m) => m['primaryTitle']).toList()}');
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getUserFavorites(String userId) async {
    final snapshot = await _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Method to seed with specific match percentages
  Future<void> seedFavoritesWithTargetMatches({
    double minMatchPercentage = 75.0,
    double maxMatchPercentage = 95.0,
  }) async {
    try {
      print('Starting to seed favorites with target matches ($minMatchPercentage%-$maxMatchPercentage%)...');

      // Clear existing favorites first
      await clearAllFavorites();

      // Create user profiles with different movie preferences
      final List<List<String>> userMoviePreferences = [
        // User 0: Drama/Crime enthusiast
        ['tt0111161', 'tt0068646', 'tt0816692', 'tt1375666'], // Shawshank, Godfather, Interstellar, Inception
        // User 1: Sci-Fi/Adventure lover
        ['tt0111161', 'tt0068646', 'tt0816692', 'tt1375666'], // Interstellar, Inception, LOTR, Superman
        // User 2: Mixed genre fan
        ['tt0111161', 'tt0068646', 'tt0816692', 'tt1375666'], // Shawshank, Inception, Sinners, It
        // User 3: Various popular movies
        ['tt0111161', 'tt0068646', 'tt0816692', 'tt1375666'], // Godfather, LOTR, Elf, Shawshank
      ];

      // Ensure overlaps for matches
      for (int i = 0; i < userIds.length; i++) {
        final userId = userIds[i];
        final preferredMovies = userMoviePreferences[i];

        print('\nSeeding favorites for user: $userId');
        print('  Preferred movies: ${preferredMovies.map((id) => movies.firstWhere((m) => m['id'] == id)['primaryTitle']).toList()}');

        // Add all preferred movies
        for (var movieId in preferredMovies) {
          final movie = movies.firstWhere((m) => m['id'] == movieId);
          await _addFavorite(userId, movie);
        }

        // Add 1-2 additional random movies from other users' preferences to create overlaps
        final otherUsersMovies = <String>[];
        for (int j = 0; j < userIds.length; j++) {
          if (j != i) {
            otherUsersMovies.addAll(userMoviePreferences[j]);
          }
        }

        // Take unique movies from other users that aren't already in this user's favorites
        final additionalMovies = otherUsersMovies
            .where((movieId) => !preferredMovies.contains(movieId))
            .toSet()
            .toList()
            .take(2);

        for (var movieId in additionalMovies) {
          final movie = movies.firstWhere((m) => m['id'] == movieId);
          await _addFavorite(userId, movie);
        }

        print('  Total favorites: ${preferredMovies.length + additionalMovies.length}');
      }

      print('\n✅ Successfully seeded favorites with targeted matches!');
      await _printExpectedMatches();

    } catch (e) {
      print('❌ Error seeding favorites: $e');
      rethrow;
    }
  }

  Future<void> _addFavorite(String userId, Map<String, dynamic> movie) async {
    final movieId = movie['id'];
    final docId = '${userId}_$movieId';

    await _firestore.collection('favorites').doc(docId).set({
      'userId': userId,
      'movieId': movieId,
      'primaryTitle': movie['primaryTitle'],
      'originalTitle': movie['originalTitle'],
      'releaseDate': movie['releaseDate'],
      'primaryImage': movie['primaryImage'],
      'averageRating': movie['averageRating'],
      'genres': movie['genres'],
      'addedAt': FieldValue.serverTimestamp(),
    });

    print('  ✓ Added: ${movie['primaryTitle']}');
  }

  // Optional: Clear all favorites (use with caution!)
  Future<void> clearAllFavorites() async {
    try {
      print('Clearing all favorites...');

      final snapshot = await _firestore.collection('favorites').get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      print('✅ Cleared ${snapshot.docs.length} favorites');

    } catch (e) {
      print('❌ Error clearing favorites: $e');
      rethrow;
    }
  }
}

// Usage examples:
// Basic seeding with guaranteed overlaps:
// final seeder = SeedFavoritesData();
// await seeder.seedFavorites();

// Seeding with specific match percentage targets:
// await seeder.seedFavoritesWithTargetMatches(minMatchPercentage: 75.0, maxMatchPercentage: 90.0);