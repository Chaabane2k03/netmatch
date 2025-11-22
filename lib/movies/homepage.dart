import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<dynamic> trendingMovies = [];
  List<dynamic> topRatedMovies = [];
  List<dynamic> popularMovies = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMovies();
  }

  // Your RapidAPI key
  Future<void> fetchMovies() async {
    const apiKey = '085d820d8emshce483d7a1ac0906p11989ajsn9f0c6d6465fd';
    const apiHost = 'imdb236.p.rapidapi.com';

    try {
      // Trending movies
      final trendingResponse = await http.get(
        Uri.parse('https://$apiHost/api/imdb/most-popular-movies'),
        headers: {
          'x-rapidapi-key': apiKey,
          'x-rapidapi-host': apiHost,
        },
      );
      print("TRENDING STATUS: ${trendingResponse.statusCode}");
      /*print("TRENDING BODY: ${trendingResponse.body}");*/

      // Top rated movies
      final topRatedResponse = await http.get(
        Uri.parse('https://imdb236.p.rapidapi.com/api/imdb/top250-movies'),
        headers: {
          'x-rapidapi-key': apiKey,
          'x-rapidapi-host': apiHost,
        },
      );
      print("TOP RATED STATUS: ${topRatedResponse.statusCode}");
      /*print("TOP RATED BODY: ${topRatedResponse.body}");*/

      // Popular movies
      final popularResponse = await http.get(
        Uri.parse('https://imdb236.p.rapidapi.com/api/imdb/top-rated-english-movies'),
        headers: {
          'x-rapidapi-key': apiKey,
          'x-rapidapi-host': apiHost,
        },
      );
      print("POPULAR STATUS: ${popularResponse.statusCode}");
      /*print("POPULAR BODY: ${popularResponse.body}");*/

      if (trendingResponse.statusCode == 200 &&
          topRatedResponse.statusCode == 200 &&
          popularResponse.statusCode == 200) {

        final trendingData = json.decode(trendingResponse.body);
        final topRatedData = json.decode(topRatedResponse.body);
        final popularData = json.decode(popularResponse.body);

        print("trending data : ${trendingData}");

        setState(() {
          trendingMovies = List.from(trendingData);
          topRatedMovies = List.from(topRatedData);
          popularMovies = List.from(popularData).take(6).toList();

          isLoading = false;
        });


      } else {
        print('Error fetching IMDb data');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching IMDb data: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
            : CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: const Color(0xFF0F0F0F),
              elevation: 0,
              title: Row(
                children: [
                  Icon(Icons.play_arrow, color: Colors.amber[700], size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    'CineMax',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
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
            SliverToBoxAdapter(
              child: _buildSectionTitle('Continue Watching'),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: popularMovies.length,
                  itemBuilder: (context, index) {
                    return _buildContinueWatchingCard(popularMovies[index], index);
                  },
                ),
              ),
            ),

            // Trending Now
            SliverToBoxAdapter(
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
            ),

            // Top Rated
            SliverToBoxAdapter(
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

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
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
          color: isSelected ? const Color(0xFFFFC107) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFC107) : Colors.grey[800]!,
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
    final title = movie['primaryTitle'] ?? movie['originalTitle'] ?? 'Featured Movie';
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
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
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
                  label: const Text('Watch Now', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
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
            child: const Text(
              'See all',
              style: TextStyle(color: Color(0xFFFFC107)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueWatchingCard(dynamic movie, int index) {
    final title = movie['primaryTitle'] ?? movie['originalTitle'] ?? 'Unknown';
    final imageUrl = movie['primaryImage'];
    final progress = (index * 0.15 + 0.2).clamp(0.0, 1.0);

    return Container(
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
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107),
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
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieCard(dynamic movie) {
    final title = movie['primaryTitle'] ?? movie['originalTitle'] ?? 'Unknown';
    final year = movie['releaseDate']?.substring(0, 4) ?? '';
    final imageUrl = movie['primaryImage'];
    final rating = movie['averageRating']?.toString() ?? 'N/A';

    return Container(
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
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: Colors.grey[900]);
                    },
                  ),
                )
                    : const SizedBox(),
              ),
              if (rating != 'N/A')
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFFC107), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          rating,
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
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home, 'Home', true),
              _buildNavItem(Icons.explore_outlined, 'Explore', false),
              _buildNavItem(Icons.bookmark_border, 'Saved', false),
              _buildNavItem(Icons.person_outline, 'Profile', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected ? const Color(0xFFFFC107) : Colors.grey[600],
          size: 28,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFFC107) : Colors.grey[600],
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}