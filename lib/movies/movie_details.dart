import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:netmatch/movies/widgets/favorite_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MovieDetails extends StatefulWidget {
  final String movieId;
  final bool isCustomMovie;

  const MovieDetails({Key? key, required this.movieId, this.isCustomMovie = false}) : super(key: key);

  @override
  State<MovieDetails> createState() => _MovieDetailsState();
}

class _MovieDetailsState extends State<MovieDetails> {
  Map<String, dynamic>? movie;
  bool loading = true;
  bool error = false;
  Uint8List? _decodedImageBytes; // Store decoded Base64 image
  final String apiKey = "30da5f7584mshaa399720f74916ep1f44b6jsn5a241833e23a";
  final String apiHost = "imdb236.p.rapidapi.com";

  @override
  void initState() {
    super.initState();
    fetchMovieDetails();
  }

  Future<void> fetchMovieDetails() async {
    try {
      if (widget.isCustomMovie) {
        await _fetchFromFirestore();
      } else {
        await _fetchFromImdbApi();
      }
    } catch (e) {
      print('Error fetching movie details: $e');
      setState(() {
        error = true;
        loading = false;
      });
    }
  }

  Future<void> _fetchFromFirestore() async {
    try {
      print('Fetching custom movie details from Firestore: ${widget.movieId}');
      final DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('movies')
          .doc(widget.movieId)
          .get();

      if (snapshot.exists) {
        Map<String, dynamic> movieData = snapshot.data() as Map<String, dynamic>;
        movieData['id'] = snapshot.id;
        movieData['isCustom'] = true;

        if (!movieData.containsKey('primaryTitle') && movieData.containsKey('originalTitle')) {
          movieData['primaryTitle'] = movieData['originalTitle'];
        }

        if (movieData['genres'] is String) {
          movieData['genres'] = (movieData['genres'] as String).split(',');
        }

        _addDefaultValues(movieData);

        // Decode Base64 image if present
        _decodeBase64Image(movieData['primaryImage']);

        setState(() {
          movie = movieData;
          loading = false;
        });
        print('Loaded custom movie: ${movieData['primaryTitle']}');
      } else {
        setState(() {
          error = true;
          loading = false;
        });
      }
    } catch (e) {
      print('Error fetching from Firestore: $e');
      setState(() {
        error = true;
        loading = false;
      });
    }
  }

  // Decode Base64 image string to bytes
  void _decodeBase64Image(dynamic imageData) {
    if (imageData == null || imageData.toString().isEmpty) {
      _decodedImageBytes = null;
      return;
    }

    try {
      String base64String = imageData.toString();

      // Remove data URI prefix if present (e.g., "data:image/png;base64,")
      if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }

      // Remove any whitespace or newlines
      base64String = base64String.replaceAll(RegExp(r'\s'), '');

      _decodedImageBytes = base64Decode(base64String);
      print('Successfully decoded Base64 image: ${_decodedImageBytes!.length} bytes');
    } catch (e) {
      print('Error decoding Base64 image: $e');
      _decodedImageBytes = null;
    }
  }

  // Check if the image is a Base64 string
  bool _isBase64Image(dynamic imageData) {
    if (imageData == null) return false;
    String imageStr = imageData.toString();

    // Check for data URI prefix or if it's a long string without http
    return imageStr.startsWith('data:image') ||
        (!imageStr.startsWith('http') && imageStr.length > 100);
  }

  // Build image widget based on source type (Base64 or URL)
  Widget _buildMovieImage({
    required bool isCustom,
    required dynamic imageUrl,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? placeholder,
  }) {
    final defaultPlaceholder = placeholder ?? Container(
      color: Colors.grey[900],
      child: const Icon(Icons.movie, color: Colors.white54, size: 64),
    );

    // For custom movies with decoded Base64 image
    if (isCustom && _decodedImageBytes != null) {
      return Image.memory(
        _decodedImageBytes!,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          print('Error displaying Base64 image: $error');
          return defaultPlaceholder;
        },
      );
    }

    // For regular movies with URL
    if (imageUrl != null && imageUrl.toString().isNotEmpty && !_isBase64Image(imageUrl)) {
      return Image.network(
        imageUrl.toString(),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return defaultPlaceholder;
        },
      );
    }

    return defaultPlaceholder;
  }

  Future<void> _fetchFromImdbApi() async {
    try {
      print('Fetching movie details from IMDB API: ${widget.movieId}');
      final response = await http.get(
        Uri.parse('https://imdb236.p.rapidapi.com/api/imdb/${widget.movieId}'),
        headers: {
          'x-rapidapi-key': apiKey,
          'x-rapidapi-host': apiHost,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          movie = json.decode(response.body);
          movie?['isCustom'] = false;
          loading = false;
        });
        print('Loaded IMDB movie: ${movie?['primaryTitle']}');
      } else {
        setState(() {
          error = true;
          loading = false;
        });
      }
    } catch (e) {
      print('Error fetching from IMDB API: $e');
      setState(() {
        error = true;
        loading = false;
      });
    }
  }

  void _addDefaultValues(Map<String, dynamic> movieData) {
    movieData['title'] ??= movieData['primaryTitle'] ?? 'No Title';
    movieData['description'] ??= movieData['plot'] ?? 'No description available';
    movieData['averageRating'] ??= 'N/A';
    movieData['runtimeMinutes'] ??= 'N/A';
    movieData['releaseDate'] ??= '';
    movieData['genres'] ??= [];
    movieData['countriesOfOrigin'] ??= [];
    movieData['spokenLanguages'] ??= [];
    movieData['budget'] ??= 0;
    movieData['grossWorldwide'] ??= 0;
    movieData['metascore'] ??= 'N/A';
    movieData['numVotes'] ??= 0;
    movieData['interests'] ??= [];
    movieData['trailer'] ??= '';
    movieData['cast'] ??= [];
    movieData['directors'] ??= [];
    movieData['writers'] ??= [];
    movieData['productionCompanies'] ??= [];
    movieData['filmingLocations'] ??= [];
    movieData['externalLinks'] ??= [];
  }

  Future<void> _launchTrailer(String url) async {
    try {
      final Uri trailerUri = Uri.parse(url);
      if (await canLaunchUrl(trailerUri)) {
        await launchUrl(
          trailerUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch trailer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error launching trailer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String? _extractYouTubeVideoId(String url) {
    if (url.isEmpty) return null;
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
        if (uri.host.contains('youtu.be')) {
          return uri.path.substring(1);
        } else {
          return uri.queryParameters['v'];
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Container(
            height: 24,
            width: 4,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "N/A" : value,
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

  Widget _buildChipList(List<dynamic> items) {
    if (items.isEmpty) return const SizedBox();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final itemText = item.toString();
        if (itemText.isEmpty) return const SizedBox();
        return Container(
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            itemText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrailerSection() {
    if (movie == null || !movie!.containsKey('trailer')) return const SizedBox();

    final trailerUrl = movie!['trailer']?.toString() ?? '';
    final youtubeVideoId = trailerUrl.isNotEmpty ? _extractYouTubeVideoId(trailerUrl) : null;
    final hasValidTrailer = youtubeVideoId != null && youtubeVideoId.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Trailer'),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[900]!.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (hasValidTrailer) ...[
                GestureDetector(
                  onTap: () => _launchTrailer(trailerUrl),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          image: DecorationImage(
                            image: NetworkImage(
                              'https://img.youtube.com/vi/$youtubeVideoId/hqdefault.jpg',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          color: Colors.black.withOpacity(0.3),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.play_arrow, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Watch',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.movie_rounded, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Official Trailer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red),
                            ),
                            child: const Text(
                              'YouTube',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _launchTrailer(trailerUrl),
                          icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                          label: const Text(
                            'Watch on YouTube',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _launchTrailer(trailerUrl),
                        child: const Text(
                          'Open in browser',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.videocam_off_rounded,
                          color: Colors.white54,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Trailer Available',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Trailer information is not available for this movie',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () {
                          final movieTitle = movie?['primaryTitle'] ?? movie?['title'] ?? '';
                          if (movieTitle.isNotEmpty) {
                            final searchUrl =
                                'https://www.youtube.com/results?search_query=${Uri.encodeComponent('$movieTitle official trailer')}';
                            _launchTrailer(searchUrl);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Search for Trailer'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    final interests = movie?['interests'] ?? [];
    if (interests.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Interests & Themes'),
        _buildChipList(interests),
      ],
    );
  }

  Widget _buildCastMember(Map<String, dynamic> person) {
    final fullName = person['fullName']?.toString() ?? 'Unknown';
    final characters = person['characters'] ?? [];
    final character = characters.isNotEmpty ? characters[0].toString() : '';
    final imageUrl = person['primaryImage']?.toString();

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              image: imageUrl != null && imageUrl.isNotEmpty
                  ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              )
                  : null,
              color: Colors.grey[800],
              border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
            ),
            child: (imageUrl == null || imageUrl.isEmpty)
                ? const Icon(Icons.person, color: Colors.white54, size: 40)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          if (character.isNotEmpty)
            Text(
              character,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildCrewMember(Map<String, dynamic> person) {
    final fullName = person['fullName']?.toString() ?? 'Unknown';
    final job = person['job']?.toString() ?? '';
    final imageUrl = person['primaryImage']?.toString();

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              image: imageUrl != null && imageUrl.isNotEmpty
                  ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              )
                  : null,
              color: Colors.grey[800],
              border: Border.all(color: Colors.red.withOpacity(0.5), width: 1.5),
            ),
            child: (imageUrl == null || imageUrl.isEmpty)
                ? const Icon(Icons.person, color: Colors.white54, size: 30)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          if (job.isNotEmpty)
            Text(
              _formatJobTitle(job),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  String _formatJobTitle(String job) {
    return job.replaceAll('_', ' ').toUpperCase();
  }

  Widget _buildInfoChip(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return "N/A";
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return "${parsedDate.day}/${parsedDate.month}/${parsedDate.year}";
    } catch (e) {
      return date;
    }
  }

  String _getYear(String date) {
    if (date == "N/A") return "N/A";
    try {
      final parts = date.split('/');
      return parts.last;
    } catch (e) {
      return "N/A";
    }
  }

  String _formatNumber(dynamic number) {
    if (number == null) return "N/A";
    try {
      if (number is int) {
        if (number >= 1000000) {
          return '${(number / 1000000).toStringAsFixed(1)}M';
        } else if (number >= 1000) {
          return '${(number / 1000).toStringAsFixed(1)}K';
        }
        return number.toString();
      } else if (number is String) {
        final parsed = int.tryParse(number);
        if (parsed != null) {
          return _formatNumber(parsed);
        }
      }
      return number.toString();
    } catch (e) {
      return number.toString();
    }
  }

  String _getLinkType(String url) {
    if (url.contains('facebook.com')) return 'Facebook';
    if (url.contains('twitter.com')) return 'Twitter';
    if (url.contains('youtube.com')) return 'YouTube';
    if (url.contains('instagram.com')) return 'Instagram';
    return 'Website';
  }

  IconData _getLinkIcon(String url) {
    if (url.contains('facebook.com')) return Icons.facebook;
    if (url.contains('youtube.com')) return Icons.play_arrow;
    if (url.contains('instagram.com')) return Icons.camera_alt;
    return Icons.link;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.red),
              SizedBox(height: 16),
              Text(
                "Loading movie details...",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    if (error || movie == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                "Failed to load movie details",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: fetchMovieDetails,
                child: const Text(
                  "Try Again",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // All variable declarations
    final isCustom = movie?['isCustom'] ?? false;
    final title = movie!['primaryTitle'] ?? movie!['title'] ?? "No Title";
    final originalTitle = movie!['originalTitle'] ?? title;
    final imageUrl = movie!['primaryImage'];
    final rating = movie!['averageRating']?.toString() ?? "N/A";
    final description = movie!['description'] ?? movie!['plot'] ?? "No description available";
    final runtime = movie!['runtimeMinutes']?.toString() ?? "N/A";
    final releaseDate = _formatDate(movie!['releaseDate']?.toString());
    final genres = (movie!['genres'] ?? []) is String
        ? [(movie!['genres'] as String)]
        : movie!['genres'] ?? [];
    final countries = movie!['countriesOfOrigin'] ?? [];
    final languages = movie!['spokenLanguages'] ?? [];
    final budget = movie!['budget'] != null && movie!['budget'] != 0
        ? '\$${_formatNumber(movie!['budget'])}'
        : "N/A";
    final gross = movie!['grossWorldwide'] != null && movie!['grossWorldwide'] != 0
        ? '\$${_formatNumber(movie!['grossWorldwide'])}'
        : "N/A";
    final metascore = movie!['metascore']?.toString() ?? "N/A";
    final numVotes = movie!['numVotes'] != null ? _formatNumber(movie!['numVotes']) : "N/A";

    final filmingLocations = movie!['filmingLocations'] ?? [];
    final productionCompanies = movie!['productionCompanies'] ?? [];
    final externalLinks = movie!['externalLinks'] ?? [];

    final directors = (movie!['directors'] ?? [])
        .where((person) => person['job']?.toString().toLowerCase() == 'director')
        .toList();
    final writers = (movie!['writers'] ?? [])
        .where((person) => person['job']?.toString().toLowerCase() == 'writer')
        .toList();
    final cast = (movie!['cast'] ?? [])
        .where((person) =>
    person['job']?.toString().toLowerCase() == 'actor' ||
        person['job']?.toString().toLowerCase() == 'actress')
        .toList();
    final crew = (movie!['cast'] ?? []).where((person) {
      final job = person['job']?.toString().toLowerCase() ?? '';
      return job == 'producer' ||
          job == 'composer' ||
          job == 'cinematographer' ||
          job == 'editor' ||
          job == 'production_designer' ||
          job == 'casting_director';
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.black,
            expandedHeight: 200,
            floating: false,
            pinned: true,
            actions: [
              if (!isCustom)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FavoriteButton(
                    movie: {
                      'id': widget.movieId,
                      'primaryTitle': movie!['primaryTitle'] ?? movie!['title'] ?? 'No Title',
                      'originalTitle': movie!['originalTitle'],
                      'releaseDate': movie!['releaseDate'],
                      'primaryImage': movie!['primaryImage'],
                      'averageRating': movie!['averageRating'],
                      'genres': movie!['genres'] ?? [],
                    },
                    size: 28,
                    activeColor: Colors.red,
                    inactiveColor: Colors.white,
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Updated to handle Base64 images for custom movies
              background: _buildAppBarBackground(isCustom, imageUrl),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom badge for Firestore movies
                  if (isCustom)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.cloud_upload, color: Colors.red[300]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Our Pick - By community demand',
                              style: TextStyle(
                                color: Colors.red[100],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900]!.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        if ((originalTitle ?? '') != title) ...[
                          const SizedBox(height: 4),
                          Text(
                            originalTitle ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildInfoChip(Icons.star, rating, 'IMDb', Colors.amber),
                            const SizedBox(width: 12),
                            _buildInfoChip(Icons.access_time, '$runtime min', 'Duration', Colors.blue),
                            const SizedBox(width: 12),
                            _buildInfoChip(Icons.calendar_today, _getYear(releaseDate), 'Year', Colors.green),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Rating stats
                  if (rating != 'N/A' || metascore != 'N/A' || numVotes != 'N/A')
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900]!.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (rating != 'N/A') _buildRatingStat('IMDb', rating, Icons.star, Colors.amber),
                          if (metascore != 'N/A')
                            _buildRatingStat('Metascore', metascore, Icons.assessment, Colors.blue),
                          if (numVotes != 'N/A') _buildRatingStat('Votes', numVotes, Icons.people, Colors.green),
                        ],
                      ),
                    ),
                  if (rating != 'N/A' || metascore != 'N/A' || numVotes != 'N/A') const SizedBox(height: 24),
                  // Trailer Section
                  _buildTrailerSection(),
                  const SizedBox(height: 24),
                  // Synopsis
                  _buildSectionTitle('Synopsis'),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900]!.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                  // Genres
                  if (genres.isNotEmpty) ...[
                    _buildSectionTitle('Genres'),
                    _buildChipList(genres),
                    const SizedBox(height: 24),
                  ],
                  // Interests
                  _buildInterestsSection(),
                  const SizedBox(height: 24),
                  // Movie Details
                  _buildSectionTitle('Movie Details'),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900]!.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        if (releaseDate.isNotEmpty) _buildInfoRow('Release Date', releaseDate),
                        if (countries.isNotEmpty) _buildInfoRow('Countries', countries.join(', ')),
                        if (languages.isNotEmpty) _buildInfoRow('Languages', languages.join(', ')),
                        if (budget != 'N/A') _buildInfoRow('Budget', budget),
                        if (gross != 'N/A') _buildInfoRow('Worldwide Gross', gross),
                        if (filmingLocations.isNotEmpty)
                          _buildInfoRow('Filming Locations', filmingLocations.join(', ')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Directors
                  if (directors.isNotEmpty) ...[
                    _buildSectionTitle('Directors'),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: directors.length,
                        itemBuilder: (context, index) => _buildCrewMember(directors[index]),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Writers
                  if (writers.isNotEmpty) ...[
                    _buildSectionTitle('Writers'),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: writers.length,
                        itemBuilder: (context, index) => _buildCrewMember(writers[index]),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Cast
                  if (cast.isNotEmpty) ...[
                    _buildSectionTitle('Cast'),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: cast.length,
                        itemBuilder: (context, index) => _buildCastMember(cast[index]),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Crew
                  if (crew.isNotEmpty) ...[
                    _buildSectionTitle('Crew'),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: crew.length,
                        itemBuilder: (context, index) => _buildCrewMember(crew[index]),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Production Companies
                  if (productionCompanies.isNotEmpty) ...[
                    _buildSectionTitle('Production Companies'),
                    _buildChipList(
                      productionCompanies
                          .map((company) => company['name']?.toString() ?? '')
                          .where((name) => name.isNotEmpty)
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // External Links
                  if (externalLinks.isNotEmpty) ...[
                    _buildSectionTitle('Follow & Watch'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: externalLinks.map<Widget>((link) {
                        final linkStr = link.toString();
                        if (linkStr.isEmpty) return const SizedBox();
                        return ActionChip(
                          avatar: Icon(_getLinkIcon(linkStr), color: Colors.white, size: 16),
                          label: Text(
                            _getLinkType(linkStr),
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.blue.withOpacity(0.8),
                          onPressed: () => _launchTrailer(linkStr),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build app bar background with Base64 support
  Widget _buildAppBarBackground(bool isCustom, dynamic imageUrl) {
    // For custom movies with decoded Base64 image
    if (isCustom && _decodedImageBytes != null) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.black.withOpacity(0.3),
          BlendMode.darken,
        ),
        child: Image.memory(
          _decodedImageBytes!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[900],
              child: const Icon(Icons.movie, color: Colors.white54, size: 64),
            );
          },
        ),
      );
    }

    // For regular movies with URL
    if (imageUrl != null && imageUrl.toString().isNotEmpty && !_isBase64Image(imageUrl)) {
      return Image.network(
        imageUrl.toString(),
        fit: BoxFit.cover,
        color: Colors.black.withOpacity(0.3),
        colorBlendMode: BlendMode.darken,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[900],
            child: const Icon(Icons.movie, color: Colors.white54, size: 64),
          );
        },
      );
    }

    // Fallback placeholder
    return Container(
      color: Colors.grey[900],
      child: const Icon(Icons.movie, color: Colors.white54, size: 64),
    );
  }
}