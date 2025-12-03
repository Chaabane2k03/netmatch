import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class MoviesPage extends StatefulWidget {
  const MoviesPage({Key? key}) : super(key: key);

  @override
  State<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends State<MoviesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // IMDb API Configuration
  final String _imdbApiKey = '15eac98273msh04a9da2a56942f2p17dcc2jsn41c6c8689c66';
  final String _imdbHost = 'imdb236.p.rapidapi.com';

  // Statistics
  int _totalUsers = 0;
  int _totalMovies = 0;
  double _averageUserAge = 0;
  Map<String, int> _genreDistribution = {};
  Map<String, double> _topRatedMovies = {}; // Changed to double for proper sorting
  Map<String, int> _userActivity = {};
  List<Map<String, dynamic>> _recentFavorites = [];
  List<Map<String, dynamic>> _trendingMovies = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all data in parallel
      await Future.wait([
        _loadUserStatistics(),
        _loadFavoriteStatistics(),
        _loadRecentFavorites(),
        _fetchTrendingMovies(),
      ]);
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserStatistics() async {
    final usersSnapshot = await _firestore.collection('users').get();

    setState(() {
      _totalUsers = usersSnapshot.docs.length;

      // Calculate average age
      int totalAge = 0;
      int usersWithAge = 0;

      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        if (data['age'] != null) {
          totalAge += data['age'] as int;
          usersWithAge++;
        }

        // Track user activity by month
        final createdAt = data['createdAt'] as Timestamp;
        final month = DateTime(createdAt.toDate().year, createdAt.toDate().month).toString();
        _userActivity[month] = (_userActivity[month] ?? 0) + 1;
      }

      _averageUserAge = usersWithAge > 0 ? totalAge / usersWithAge : 0;
    });
  }

  Future<void> _loadFavoriteStatistics() async {
    final favoritesSnapshot = await _firestore.collection('favorites').get();

    setState(() {
      _totalMovies = favoritesSnapshot.docs.length;

      for (final doc in favoritesSnapshot.docs) {
        final data = doc.data();

        // Collect genre distribution
        if (data['genres'] != null && data['genres'] is List) {
          for (final genre in data['genres'] as List) {
            _genreDistribution[genre] = (_genreDistribution[genre] ?? 0) + 1;
          }
        }

        // Collect top rated movies
        final title = data['primaryTitle'] ?? 'Unknown';
        final rating = data['averageRating'] ?? 0.0;
        if (rating > 0) {
          _topRatedMovies[title] = (rating as double);
        }
      }

      // Sort genre distribution by count
      _genreDistribution = Map.fromEntries(
          _genreDistribution.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value))
      );

      // Sort top rated movies
      _topRatedMovies = Map.fromEntries(
          _topRatedMovies.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value))
      );
    });
  }

  Future<void> _loadRecentFavorites() async {
    final favoritesSnapshot = await _firestore.collection('favorites')
        .orderBy('addedAt', descending: true)
        .limit(5)
        .get();

    final recentFavorites = <Map<String, dynamic>>[];

    for (final doc in favoritesSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      // Get user info for each favorite
      final userId = data['userId'];
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;

      recentFavorites.add({
        'movieTitle': data['primaryTitle'] ?? 'Unknown',
        'userName': userData?['fullName'] ?? 'Unknown User',
        'userEmail': userData?['email'] ?? 'Unknown',
        'addedAt': (data['addedAt'] as Timestamp).toDate(),
        'rating': data['averageRating'] ?? 0,
        'image': data['primaryImage'],
      });
    }

    setState(() {
      _recentFavorites = recentFavorites;
    });
  }

  Future<void> _fetchTrendingMovies() async {
    try {
      final uri = Uri.parse('https://$_imdbHost/auto-complete');
      final response = await http.get(
        uri,
        headers: {
          'X-RapidAPI-Key': _imdbApiKey,
          'X-RapidAPI-Host': _imdbHost,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['d'] ?? [];

        final trendingMovies = <Map<String, dynamic>>[];
        for (final result in results.take(5)) {
          trendingMovies.add({
            'title': result['l'] ?? 'Unknown',
            'year': result['y']?.toString() ?? 'N/A',
            'image': result['i']?['imageUrl'] ?? '',
            'type': result['q'] ?? 'Unknown',
            'rank': result['rank'] ?? 0,
          });
        }

        setState(() {
          _trendingMovies = trendingMovies;
        });
      }
    } catch (e) {
      print('Error fetching trending movies: $e');
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreDistribution() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.category, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Genre Distribution',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Total: $_totalMovies movies',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_genreDistribution.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No genre data available',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _genreDistribution.length,
                  itemBuilder: (context, index) {
                    final entry = _genreDistribution.entries.toList()[index];
                    final percentage = (_totalMovies > 0)
                        ? (entry.value / _totalMovies * 100).toStringAsFixed(1)
                        : '0';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '$percentage% (${entry.value})',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: _totalMovies > 0 ? entry.value / _totalMovies : 0,
                            backgroundColor: Colors.grey[800],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getGenreColor(entry.key),
                            ),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
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

  Color _getGenreColor(String genre) {
    final colors = {
      'Drama': Colors.red,
      'Action': Colors.orange,
      'Comedy': Colors.yellow,
      'Romance': Colors.pink,
      'Thriller': Colors.purple,
      'Horror': Colors.green,
      'Sci-Fi': Colors.blue,
      'Crime': Colors.amber,
      'Family': Colors.lightBlue,
      'Documentary': Colors.teal,
    };

    return colors[genre] ?? Colors.grey;
  }

  Widget _buildRecentFavorites() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Recent Favorites',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                  onPressed: _loadDashboardData,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentFavorites.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No recent favorites',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentFavorites.length,
                  itemBuilder: (context, index) {
                    final favorite = _recentFavorites[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: favorite['image'] != null
                                  ? DecorationImage(
                                image: NetworkImage(favorite['image']),
                                fit: BoxFit.cover,
                              )
                                  : null,
                              color: Colors.grey[800],
                            ),
                            child: favorite['image'] == null
                                ? const Center(
                              child: Icon(Icons.movie, color: Colors.white54, size: 24),
                            )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  favorite['movieTitle'],
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
                                  'Added by: ${favorite['userName']}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${favorite['rating']}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    Expanded(
                                      child: Text(
                                        _formatDate(favorite['addedAt']),
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildTopRatedMovies() {
    final topMovies = _topRatedMovies.entries.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Top Rated Movies',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Avg: ${_calculateAverageRating()}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (topMovies.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No rated movies yet',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topMovies.length,
                  itemBuilder: (context, index) {
                    final movie = topMovies[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _getRankColor(index + 1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              movie.key,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${movie.value.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
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

  String _calculateAverageRating() {
    if (_topRatedMovies.isEmpty) return '0.0';
    final total = _topRatedMovies.values.reduce((a, b) => a + b);
    final average = total / _topRatedMovies.length;
    return average.toStringAsFixed(1);
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.grey[800]!;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.red),
      )
          : SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Movie Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Statistics & Insights',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),

                // Statistics Cards - Responsive Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: constraints.maxWidth > 600 ? 2.0 : 1.5,
                      children: [
                        _buildStatCard(
                          'Total Users',
                          _totalUsers.toString(),
                          Icons.people,
                          Colors.red,
                        ),
                        _buildStatCard(
                          'Total Movies',
                          _totalMovies.toString(),
                          Icons.movie,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Avg User Age',
                          _averageUserAge.toStringAsFixed(0),
                          Icons.cake,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Top Rated Avg',
                          _calculateAverageRating(),
                          Icons.star,
                          Colors.amber,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Genre Distribution & Top Rated - Responsive layout
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 800) {
                      // Desktop/Tablet layout
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildGenreDistribution(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: _buildTopRatedMovies(),
                          ),
                        ],
                      );
                    } else {
                      // Mobile layout
                      return Column(
                        children: [
                          _buildGenreDistribution(),
                          const SizedBox(height: 16),
                          _buildTopRatedMovies(),
                        ],
                      );
                    }
                  },
                ),

                const SizedBox(height: 24),

                // Recent Favorites
                _buildRecentFavorites(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}