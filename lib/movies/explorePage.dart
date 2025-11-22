import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExplorePage extends StatefulWidget {
  const ExplorePage({Key? key}) : super(key: key);

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> allMovies = [];
  List<dynamic> filteredMovies = [];
  bool isLoading = true;
  String selectedGenre = 'All';
  String selectedSort = 'Popular';

  final List<String> genres = [
    'All',
    'Action',
    'Comedy',
    'Drama',
    'Thriller',
    'Sci-Fi',
    'Horror',
    'Romance',
  ];

  final List<String> sortOptions = [
    'Popular',
    'Top Rated',
    'Recent',
    'A-Z',
  ];

  @override
  void initState() {
    super.initState();
    fetchExploreMovies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchExploreMovies() async {
    const apiKey = '085d820d8emshce483d7a1ac0906p11989ajsn9f0c6d6465fd';
    const apiHost = 'imdb236.p.rapidapi.com';

    try {
      // Fetch multiple categories for explore
      final popularResponse = await http.get(
        Uri.parse('https://$apiHost/api/imdb/most-popular-movies'),
        headers: {
          'x-rapidapi-key': apiKey,
          'x-rapidapi-host': apiHost,
        },
      );

      final topRatedResponse = await http.get(
        Uri.parse('https://imdb236.p.rapidapi.com/api/imdb/top250-movies'),
        headers: {
          'x-rapidapi-key': apiKey,
          'x-rapidapi-host': apiHost,
        },
      );

      if (popularResponse.statusCode == 200 && topRatedResponse.statusCode == 200) {
        final popularData = json.decode(popularResponse.body);
        final topRatedData = json.decode(topRatedResponse.body);

        // Combine and remove duplicates
        List<dynamic> combined = [...popularData, ...topRatedData];
        Map<String, dynamic> uniqueMovies = {};

        for (var movie in combined) {
          String id = movie['id'] ?? movie['primaryTitle'] ?? '';
          if (id.isNotEmpty && !uniqueMovies.containsKey(id)) {
            uniqueMovies[id] = movie;
          }
        }

        setState(() {
          allMovies = uniqueMovies.values.toList();
          filteredMovies = allMovies;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching movies: $e');
      setState(() => isLoading = false);
    }
  }

  void _filterMovies() {
    setState(() {
      filteredMovies = allMovies.where((movie) {
        final title = (movie['primaryTitle'] ?? movie['originalTitle'] ?? '').toLowerCase();
        final searchQuery = _searchController.text.toLowerCase();

        // Search filter
        if (searchQuery.isNotEmpty && !title.contains(searchQuery)) {
          return false;
        }

        // Genre filter
        if (selectedGenre != 'All') {
          final genres = movie['genres'];

          if (genres == null) {
            return false;
          }

          bool hasGenre = false;

          try {
            if (genres is List) {
              for (var genre in genres) {
                String genreName = '';

                // Safely extract the genre name
                if (genre is String) {
                  genreName = genre.toLowerCase();
                } else {
                  // It's some kind of object, convert to string
                  genreName = genre.toString().toLowerCase();
                }

                if (genreName.contains(selectedGenre.toLowerCase())) {
                  hasGenre = true;
                  break;
                }
              }
            } else if (genres is String) {
              hasGenre = genres.toLowerCase().contains(selectedGenre.toLowerCase());
            }
          } catch (e) {
            print('Error filtering genre: $e');
            return false;
          }

          if (!hasGenre) {
            return false;
          }
        }

        return true;
      }).toList();

      // Sort filter
      if (selectedSort == 'Top Rated') {
        filteredMovies.sort((a, b) {
          double ratingA = double.tryParse(a['averageRating']?.toString() ?? '0') ?? 0;
          double ratingB = double.tryParse(b['averageRating']?.toString() ?? '0') ?? 0;
          return ratingB.compareTo(ratingA);
        });
      } else if (selectedSort == 'Recent') {
        filteredMovies.sort((a, b) {
          String yearA = a['releaseDate']?.toString() ?? '0';
          String yearB = b['releaseDate']?.toString() ?? '0';
          return yearB.compareTo(yearA);
        });
      } else if (selectedSort == 'A-Z') {
        filteredMovies.sort((a, b) {
          String titleA = a['primaryTitle'] ?? a['originalTitle'] ?? '';
          String titleB = b['primaryTitle'] ?? b['originalTitle'] ?? '';
          return titleA.compareTo(titleB);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.red))
            : CustomScrollView(
          slivers: [
            // App Bar with Search
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: const Color(0xFF0F0F0F),
              elevation: 0,
              expandedHeight: 120,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 10),
                  child: Column(
                    children: [
                      // Search Bar
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search movies...',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            prefixIcon: const Icon(Icons.search, color: Colors.red),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                });
                                _filterMovies();
                              },
                            )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          ),
                          onChanged: (value) {
                            setState(() {}); // Trigger rebuild for suffixIcon
                            _filterMovies();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              title: const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Explore',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Genre Filter
            SliverToBoxAdapter(
              child: Container(
                height: 50,
                margin: const EdgeInsets.symmetric(vertical: 12),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: genres.length,
                  itemBuilder: (context, index) {
                    return _buildGenreChip(genres[index]);
                  },
                ),
              ),
            ),

            // Sort and Results Count
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filteredMovies.length} Movies',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    _buildSortDropdown(),
                  ],
                ),
              ),
            ),

            // Movies Grid
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: filteredMovies.isEmpty
                  ? SliverToBoxAdapter(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 100),
                      Icon(Icons.search_off, size: 80, color: Colors.grey[700]),
                      const SizedBox(height: 16),
                      Text(
                        'No movies found',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.58,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 20,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    return _buildMovieGridItem(filteredMovies[index]);
                  },
                  childCount: filteredMovies.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreChip(String genre) {
    final isSelected = selectedGenre == genre;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGenre = genre;
          _filterMovies();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red : Colors.black,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey[800]!,
          ),
        ),
        child: Center(
          child: Text(
            genre,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: DropdownButton<String>(
        value: selectedSort,
        underline: const SizedBox(),
        dropdownColor: const Color(0xFF1A1A1A),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.red),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        items: sortOptions.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              selectedSort = newValue;
              _filterMovies();
            });
          }
        },
      ),
    );
  }

  Widget _buildMovieGridItem(dynamic movie) {
    final title = movie['primaryTitle'] ?? movie['originalTitle'] ?? 'Unknown';
    final year = movie['releaseDate']?.substring(0, 4) ?? '';
    final imageUrl = movie['primaryImage'];
    final rating = movie['averageRating']?.toString() ?? 'N/A';

    return GestureDetector(
      onTap: () {
        // Navigate to movie details
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[900],
                ),
                child: imageUrl != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 240,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: Icon(Icons.movie, color: Colors.grey, size: 50),
                        ),
                      );
                    },
                  ),
                )
                    : Center(
                  child: Icon(Icons.movie, color: Colors.grey[700], size: 50),
                ),
              ),
              // Rating Badge
              if (rating != 'N/A')
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.red, size: 14),
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
              // Bookmark Icon
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bookmark_border,
                    color: Colors.white,
                    size: 18,
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
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (year.isNotEmpty)
            Text(
              year,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}