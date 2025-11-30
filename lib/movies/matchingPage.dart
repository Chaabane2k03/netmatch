// lib/pages/matching_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../services/match_service.dart';

class MatchingPage extends StatefulWidget {
  const MatchingPage({super.key});

  @override
  State<MatchingPage> createState() => _MatchingPageState();
}

class _MatchingPageState extends State<MatchingPage> {
  final MatchingService _matchingService = MatchingService();
  final CardSwiperController _swiperController = CardSwiperController();

  List<UserMatch> _matches = [];
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;

  // Netflix colors
  static const Color netflixRed = Color(0xFFE50914);
  static const Color netflixBlack = Color(0xFF141414);
  static const Color netflixDarkGrey = Color(0xFF1F1F1F);

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      final matches = await _matchingService.findMatchesForUser(currentUserId);
      setState(() {
        _matches = matches;
        _isLoading = false;
        _currentIndex = 0;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: netflixBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'MATCHES',
          style: TextStyle(
            color: netflixRed,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadMatches,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: netflixRed),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_matches.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Card counter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_currentIndex + 1}',
                style: const TextStyle(
                  color: netflixRed,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' / ${_matches.length}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        // Card swiper
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CardSwiper(
              controller: _swiperController,
              cardsCount: _matches.length,
              numberOfCardsDisplayed: _matches.length > 2 ? 3 : _matches.length,
              backCardOffset: const Offset(0, 40),
              padding: const EdgeInsets.only(bottom: 100),
              onSwipe: _onSwipe,
              onUndo: _onUndo,
              allowedSwipeDirection: const AllowedSwipeDirection.symmetric(
                horizontal: true,
              ),
              cardBuilder: (context, index, horizontalOffsetPercentage, verticalOffsetPercentage) {
                return _buildSwipeCard(_matches[index]);
              },
            ),
          ),
        ),
        // Action buttons
        _buildActionButtons(),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSwipeCard(UserMatch match) {
    return GestureDetector(
      onTap: () => _showMatchDetails(match),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image or gradient
              _buildCardBackground(match),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.9),
                    ],
                    stops: const [0.3, 0.6, 1.0],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Match percentage badge
                    Align(
                      alignment: Alignment.topRight,
                      child: _buildMatchBadge(match.matchPercentage),
                    ),
                    const Spacer(),
                    // User info
                    Text(
                      match.matchedUserName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.movie_outlined,
                          color: netflixRed,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${match.commonMovieCount} movies in common',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Common movies preview
                    if (match.commonMovies.isNotEmpty) _buildMoviesPreview(match),
                    const SizedBox(height: 16),
                    // Tap for more hint
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Tap for details',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardBackground(UserMatch match) {
    if (match.matchedUserImage != null && match.matchedUserImage!.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(match.matchedUserImage!),
          fit: BoxFit.cover,
        );
      } catch (e) {
        // Fall through to default
      }
    }

    // Default gradient background with initial
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D2D2D),
            netflixDarkGrey,
            netflixBlack,
          ],
        ),
      ),
      child: Center(
        child: Text(
          match.matchedUserName.isNotEmpty
              ? match.matchedUserName[0].toUpperCase()
              : '?',
          style: TextStyle(
            fontSize: 120,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchBadge(double percentage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: netflixRed,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: netflixRed.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.favorite,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            '${percentage.toStringAsFixed(0)}% Match',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoviesPreview(UserMatch match) {
    final previewMovies = match.commonMovies.take(3).toList();

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: previewMovies.length,
        itemBuilder: (context, index) {
          final movie = previewMovies[index];
          return Container(
            width: 55,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: movie.primaryImage != null
                  ? Image.network(
                movie.primaryImage!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildMoviePlaceholder(),
              )
                  : _buildMoviePlaceholder(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoviePlaceholder() {
    return Container(
      color: netflixDarkGrey,
      child: const Icon(
        Icons.movie,
        color: Colors.white30,
        size: 24,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Skip button
          _buildActionButton(
            icon: Icons.close,
            color: Colors.grey[700]!,
            size: 60,
            onTap: () => _swiperController.swipe(CardSwiperDirection.left),
          ),
          // Undo button
          _buildActionButton(
            icon: Icons.replay,
            color: Colors.amber,
            size: 50,
            onTap: () => _swiperController.undo(),
          ),
          // Like button
          _buildActionButton(
            icon: Icons.favorite,
            color: netflixRed,
            size: 60,
            onTap: () => _swiperController.swipe(CardSwiperDirection.right),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: netflixDarkGrey,
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: size * 0.45,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: netflixDarkGrey,
                border: Border.all(color: netflixRed.withOpacity(0.3)),
              ),
              child: Icon(
                Icons.movie_filter_outlined,
                size: 60,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No Matches Yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'We couldn\'t find users who share at least 60% of your favorite movies. Add more favorites!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loadMatches,
              style: ElevatedButton.styleFrom(
                backgroundColor: netflixRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Refresh',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: netflixRed,
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadMatches,
              style: ElevatedButton.styleFrom(
                backgroundColor: netflixRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (currentIndex != null) {
      setState(() {
        _currentIndex = currentIndex;
      });
    }

    if (direction == CardSwiperDirection.right) {
      // User liked - you can add logic here to save the like
      _showLikeSnackbar(_matches[previousIndex]);
    }

    return true;
  }

  bool _onUndo(int? previousIndex, int currentIndex, CardSwiperDirection direction) {
    setState(() {
      _currentIndex = currentIndex;
    });
    return true;
  }

  void _showLikeSnackbar(UserMatch match) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.favorite, color: Colors.white),
            const SizedBox(width: 12),
            Text('You liked ${match.matchedUserName}!'),
          ],
        ),
        backgroundColor: netflixRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showMatchDetails(UserMatch match) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDetailsSheet(match),
    );
  }

  Widget _buildDetailsSheet(UserMatch match) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: netflixDarkGrey,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    _buildProfileAvatar(match, 35),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            match.matchedUserName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${match.matchPercentage.toStringAsFixed(0)}% match',
                            style: const TextStyle(
                              color: netflixRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Divider
              Container(
                height: 1,
                color: Colors.grey[800],
              ),
              // Section title
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.movie, color: netflixRed, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      'Movies in Common (${match.commonMovieCount})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Movies list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: match.commonMovies.length,
                  itemBuilder: (context, index) {
                    return _buildMovieListItem(match.commonMovies[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar(UserMatch match, double radius) {
    if (match.matchedUserImage != null && match.matchedUserImage!.isNotEmpty) {
      try {
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(base64Decode(match.matchedUserImage!)),
        );
      } catch (e) {
        // Fall through
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: netflixBlack,
      child: Text(
        match.matchedUserName.isNotEmpty
            ? match.matchedUserName[0].toUpperCase()
            : '?',
        style: TextStyle(
          fontSize: radius,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMovieListItem(Favorite movie) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: netflixBlack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Movie poster
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(12),
            ),
            child: SizedBox(
              width: 70,
              height: 100,
              child: movie.primaryImage != null
                  ? Image.network(
                movie.primaryImage!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildMoviePlaceholder(),
              )
                  : _buildMoviePlaceholder(),
            ),
          ),
          // Movie info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.primaryTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (movie.averageRating != null) ...[
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          movie.averageRating!.toStringAsFixed(1),
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (movie.releaseDate != null)
                        Text(
                          movie.releaseDate!.split('-').first,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: movie.genres.take(2).map((genre) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: netflixRed.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          genre,
                          style: const TextStyle(
                            color: netflixRed,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}