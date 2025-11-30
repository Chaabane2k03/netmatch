// lib/services/matching_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Threshold for matching (75%)
  static const double matchThreshold = 0.6;

  /// Get all matches for a specific user
  Future<List<UserMatch>> findMatchesForUser(String userId) async {
    // 1. Get current user's favorites
    final userFavorites = await _getUserFavorites(userId);

    if (userFavorites.isEmpty) {
      return [];
    }

    // Extract movie IDs from user's favorites
    final userMovieIds = userFavorites.map((f) => f.movieId).toSet();

    // 2. Get all other users
    final usersSnapshot = await _firestore
        .collection('users')
        .where('uid', isNotEqualTo: userId)
        .get();

    List<UserMatch> matches = [];

    // 3. Check each user for matches
    for (final userDoc in usersSnapshot.docs) {
      final otherUserId = userDoc.data()['uid'] as String;
      final otherUserFavorites = await _getUserFavorites(otherUserId);

      if (otherUserFavorites.isEmpty) continue;

      // Extract other user's movie IDs
      final otherUserMovieIds = otherUserFavorites.map((f) => f.movieId).toSet();

      // 4. Calculate match percentage
      final commonMovies = userMovieIds.intersection(otherUserMovieIds);
      final matchPercentage = commonMovies.length / userMovieIds.length;

      // 5. If >= 75%, it's a match
      if (matchPercentage >= matchThreshold) {
        // Get common movie details
        final commonFavorites = userFavorites
            .where((f) => commonMovies.contains(f.movieId))
            .toList();

        matches.add(UserMatch(
          matchedUserId: otherUserId,
          matchedUserName: userDoc.data()['fullName'] as String? ?? 'Unknown',
          matchedUserImage: userDoc.data()['profileImageBase64'] as String?,
          matchedUserEmail: userDoc.data()['email'] as String?,
          matchPercentage: matchPercentage * 100,
          commonMovies: commonFavorites,
          commonMovieCount: commonMovies.length,
          totalUserFavorites: userMovieIds.length,
        ));
      }
    }

    // Sort by match percentage (highest first)
    matches.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));

    return matches;
  }

  /// Get favorites for a specific user
  Future<List<Favorite>> _getUserFavorites(String userId) async {
    final snapshot = await _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) => Favorite.fromFirestore(doc)).toList();
  }

  /// Check if two specific users are a match
  Future<MatchResult> checkMatch(String userId1, String userId2) async {
    final user1Favorites = await _getUserFavorites(userId1);
    final user2Favorites = await _getUserFavorites(userId2);

    if (user1Favorites.isEmpty || user2Favorites.isEmpty) {
      return MatchResult(
        isMatch: false,
        matchPercentage: 0,
        commonMovies: [],
      );
    }

    final user1MovieIds = user1Favorites.map((f) => f.movieId).toSet();
    final user2MovieIds = user2Favorites.map((f) => f.movieId).toSet();

    final commonMovieIds = user1MovieIds.intersection(user2MovieIds);

    // Get common movie details
    final commonMovies = user1Favorites
        .where((f) => commonMovieIds.contains(f.movieId))
        .toList();

    // Calculate from user1's perspective
    final matchPercentage = commonMovieIds.length / user1MovieIds.length;

    return MatchResult(
      isMatch: matchPercentage >= matchThreshold,
      matchPercentage: matchPercentage * 100,
      commonMovies: commonMovies,
    );
  }

  /// Stream matches in real-time
  Stream<List<UserMatch>> watchMatchesForUser(String userId) {
    return _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((_) => findMatchesForUser(userId));
  }
}

// Models

class Favorite {
  final String movieId;
  final String primaryTitle;
  final String? originalTitle;
  final String? primaryImage;
  final List<String> genres;
  final double? averageRating;
  final String? releaseDate;
  final DateTime addedAt;
  final String userId;

  Favorite({
    required this.movieId,
    required this.primaryTitle,
    this.originalTitle,
    this.primaryImage,
    required this.genres,
    this.averageRating,
    this.releaseDate,
    required this.addedAt,
    required this.userId,
  });

  factory Favorite.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Favorite(
      movieId: data['movieId'] as String,
      primaryTitle: data['primaryTitle'] as String? ?? '',
      originalTitle: data['originalTitle'] as String?,
      primaryImage: data['primaryImage'] as String?,
      genres: List<String>.from(data['genres'] ?? []),
      averageRating: (data['averageRating'] as num?)?.toDouble(),
      releaseDate: data['releaseDate'] as String?,
      addedAt: (data['addedAt'] as Timestamp).toDate(),
      userId: data['userId'] as String,
    );
  }
}

class UserMatch {
  final String matchedUserId;
  final String matchedUserName;
  final String? matchedUserImage;
  final String? matchedUserEmail;
  final double matchPercentage;
  final List<Favorite> commonMovies;
  final int commonMovieCount;
  final int totalUserFavorites;

  UserMatch({
    required this.matchedUserId,
    required this.matchedUserName,
    this.matchedUserImage,
    this.matchedUserEmail,
    required this.matchPercentage,
    required this.commonMovies,
    required this.commonMovieCount,
    required this.totalUserFavorites,
  });
}

class MatchResult {
  final bool isMatch;
  final double matchPercentage;
  final List<Favorite> commonMovies;

  MatchResult({
    required this.isMatch,
    required this.matchPercentage,
    required this.commonMovies,
  });
}