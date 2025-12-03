import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:netmatch/movies/explorePage.dart';
import 'package:netmatch/movies/movie_details.dart';
import 'package:netmatch/movies/profilePage.dart';
import 'package:netmatch/movies/savedPage.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:netmatch/movies/widgets/bottom_nav_bar.dart';
import 'package:netmatch/profile/edit_profile.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int botIndex = 0;
  List<dynamic> trendingMovies = [];
  List<dynamic> topRatedMovies = [];
  List<dynamic> popularMovies = [];
  bool isLoading = true;

  // Cache configuration
  static const String CACHE_KEY_TRENDING = 'home_trending_movies';
  static const String CACHE_KEY_TOP_RATED = 'home_top_rated_movies';
  static const String CACHE_KEY_POPULAR = 'home_popular_movies';
  static const String CACHE_KEY_TIMESTAMP = 'home_movies_timestamp';
  static const Duration CACHE_DURATION = Duration(hours: 6);

  @override
  void initState() {
    super.initState();
    fetchMovies();
  }

  // Check if cache is still valid
  Future<bool> _isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(CACHE_KEY_TIMESTAMP);

      if (timestamp == null) return false;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();

      return now.difference(cacheTime) < CACHE_DURATION;
    } catch (e) {
      print('Error checking cache validity: $e');
      return false;
    }
  }

  // Load movies from cache
  Future<Map<String, List<dynamic>>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final trendingData = prefs.getString(CACHE_KEY_TRENDING);
      final topRatedData = prefs.getString(CACHE_KEY_TOP_RATED);
      final popularData = prefs.getString(CACHE_KEY_POPULAR);

      if (trendingData != null && topRatedData != null && popularData != null) {
        print('✅ Loaded movies from cache');
        return {
          'trending': List<dynamic>.from(json.decode(trendingData)),
          'topRated': List<dynamic>.from(json.decode(topRatedData)),
          'popular': List<dynamic>.from(json.decode(popularData)),
        };
      }
    } catch (e) {
      print('Error loading from cache: $e');
    }
    return null;
  }

  // Save movies to cache
  Future<void> _saveToCache({
    required List<dynamic> trending,
    required List<dynamic> topRated,
    required List<dynamic> popular,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(CACHE_KEY_TRENDING, json.encode(trending));
      await prefs.setString(CACHE_KEY_TOP_RATED, json.encode(topRated));
      await prefs.setString(CACHE_KEY_POPULAR, json.encode(popular));
      await prefs.setInt(CACHE_KEY_TIMESTAMP, DateTime.now().millisecondsSinceEpoch);

      print('✅ Saved movies to cache');
    } catch (e) {
      print('Error saving to cache: $e');
    }
  }

  // Clear cache
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(CACHE_KEY_TRENDING);
      await prefs.remove(CACHE_KEY_TOP_RATED);
      await prefs.remove(CACHE_KEY_POPULAR);
      await prefs.remove(CACHE_KEY_TIMESTAMP);
      print('✅ Cache cleared');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  Future<void> fetchMovies({bool forceRefresh = false}) async {
    const apiKey = '30da5f7584mshaa399720f74916ep1f44b6jsn5a241833e23a';
    const apiHost = 'imdb236.p.rapidapi.com';

    try {
      // Check cache first (unless force refresh)
      if (!forceRefresh) {
        final isCacheValid = await _isCacheValid();

        if (isCacheValid) {
          final cachedData = await _loadFromCache();

          if (cachedData != null) {
            setState(() {
              trendingMovies = cachedData['trending']!;
              topRatedMovies = cachedData['topRated']!;
              popularMovies = cachedData['popular']!;
              isLoading = false;
            });
            return; // Use cached data, no API call needed!
          }
        }
      }

      // If no valid cache or force refresh, fetch from API
      print('🌐 Fetching movies from API...');

      // Trending movies
      final trendingResponse = await http.get(
        Uri.parse('https://$apiHost/api/imdb/most-popular-movies'),
        headers: {'x-rapidapi-key': apiKey, 'x-rapidapi-host': apiHost},
      );
      print("TRENDING STATUS: ${trendingResponse.statusCode}");

      // Top rated movies
      final topRatedResponse = await http.get(
        Uri.parse('https://imdb236.p.rapidapi.com/api/imdb/top250-movies'),
        headers: {'x-rapidapi-key': apiKey, 'x-rapidapi-host': apiHost},
      );

      print("TOP RATED STATUS: ${topRatedResponse.statusCode}");

      // Popular movies
      final popularResponse = await http.get(
        Uri.parse(
          'https://imdb236.p.rapidapi.com/api/imdb/top-rated-english-movies',
        ),
        headers: {'x-rapidapi-key': apiKey, 'x-rapidapi-host': apiHost},
      );
      print("POPULAR STATUS: ${popularResponse.statusCode}");

      if (trendingResponse.statusCode == 200 &&
          topRatedResponse.statusCode == 200 &&
          popularResponse.statusCode == 200) {
        final trendingData = json.decode(trendingResponse.body);
        final topRatedData = json.decode(topRatedResponse.body);
        final popularData = json.decode(popularResponse.body);

        print("trending data : ${trendingData}");

        final trending = List.from(trendingData);
        final topRated = List.from(topRatedData);
        final popular = List.from(popularData).take(6).toList();

        // Save to cache
        await _saveToCache(
          trending: trending,
          topRated: topRated,
          popular: popular,
        );

        setState(() {
          trendingMovies = trending;
          topRatedMovies = topRated;
          popularMovies = popular;
          isLoading = false;
        });
      } else {
        print('Error fetching IMDb data');

        // Try to load from cache as fallback
        final cachedData = await _loadFromCache();
        if (cachedData != null) {
          setState(() {
            trendingMovies = cachedData['trending']!;
            topRatedMovies = cachedData['topRated']!;
            popularMovies = cachedData['popular']!;
            isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Using cached data. Pull to refresh.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      print('Error fetching IMDb data: $e');

      // Try to load from cache as fallback
      final cachedData = await _loadFromCache();
      if (cachedData != null) {
        setState(() {
          trendingMovies = cachedData['trending']!;
          topRatedMovies = cachedData['topRated']!;
          popularMovies = cachedData['popular']!;
          isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Using cached data. Pull to refresh.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _buildPageContent() {
    switch (botIndex) {
      case 0:
        return RefreshIndicator(
          color: Colors.red,
          backgroundColor: const Color(0xFF1A1A1A),
          onRefresh: () async {
            await fetchMovies(forceRefresh: true);
          },
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                automaticallyImplyLeading: false,
                floating: true,
                backgroundColor: const Color(0xFF0F0F0F),
                elevation: 0,
                title: Row(
                  children: [
                    Image.asset("assets/logos/logo.png" , height:70 , width:70),
                    const SizedBox(width: 8),
                    const Text(
                      'Welcome !',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search, size: 28),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, size: 28),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.red, size: 28),
                    onPressed: () async {
                      setState(() => isLoading = true);
                      await fetchMovies(forceRefresh: true);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // Tab Bar
              SliverToBoxAdapter(
                child: Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildTab('Featured', 0),
                      _buildTab('Movies', 1),
                      _buildTab('TV Shows', 2),
                      _buildTab('Trending', 3),
                    ],
                  ),
                ),
              ),

              // Featured Banner
              SliverToBoxAdapter(
                child: Container(
                  height: 200,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: trendingMovies.isNotEmpty
                      ? _buildFeaturedBanner(trendingMovies[0])
                      : const SizedBox(),
                ),
              ),

              // Continue Watching
              SliverToBoxAdapter(child: _buildSectionTitle('Continue Watching')),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: popularMovies.length,
                    itemBuilder: (context, index) {
                      return _buildContinueWatchingCard(
                        popularMovies[index],
                        index,
                      );
                    },
                  ),
                ),
              ),

              // Trending Now
              /*SliverToBoxAdapter(
                child: _buildSectionTitle('Trending Now'),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 260,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: trendingMovies.length,
                    itemBuilder: (context, index) {
                      return _buildMovieCard(trendingMovies[index]);
                    },
                  ),
                ),
              ),*/

              // Top Rated

              /*SliverToBoxAdapter(
                child: _buildSectionTitle('Top Rated'),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 260,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: topRatedMovies.length,
                    itemBuilder: (context, index) {
                      return _buildMovieCard(topRatedMovies[index]);
                    },
                  ),
                ),
              ),
              */
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );

      case 1:
        return const ExplorePage();
      case 2:
        return const SavedPage();
      case 3:
        return const MyAccountPage();
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.red))
            : _buildPageContent(),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: botIndex,
        onTap: (index) {
          setState(() {
            botIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red : Colors.black,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey[800]!,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedBanner(dynamic movie) {
    final title =
        movie['primaryTitle'] ?? movie['originalTitle'] ?? 'Featured Movie';
    final imageUrl = movie['primaryImage'];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.3),
            Colors.blue.withOpacity(0.3),
          ],
        ),
      ),
      child: Stack(
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Colors.grey[900]);
                },
              ),
            ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow, color: Colors.black),
                  label: const Text(
                    'Watch Now',
                    style: TextStyle(color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('See all', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueWatchingCard(dynamic movie, int index) {
    final title = movie['primaryTitle'] ?? movie['originalTitle'] ?? 'Unknown';
    final imageUrl = movie['primaryImage'];
    final progress = (index * 0.15 + 0.2).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MovieDetails(movieId: movie['id'] ?? movie['tconst']),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[900],
                  ),
                  child: imageUrl != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      width: 140,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: Colors.grey[900]);
                      },
                    ),
                  )
                      : const SizedBox(),
                ),
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toInt()}% watched',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieCard(dynamic movie) {
    final title = movie['primaryTitle'] ?? movie['originalTitle'] ?? 'Unknown';
    final year = movie['releaseDate']?.substring(0, 4) ?? '';
    final imageUrl = movie['primaryImage'];
    final rating = movie['averageRating']?.toString() ?? 'N/A';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MovieDetails(movieId: movie['id'] ?? movie['tconst']),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[900],
                  ),
                  child: imageUrl != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      width: 140,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  )
                      : const SizedBox(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (year.isNotEmpty)
              Text(
                year,
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isSelected ? Colors.red : Colors.grey[600], size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.red : Colors.grey[600],
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}