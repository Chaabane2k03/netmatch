import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class MovieDetails extends StatefulWidget {
  final String movieId;

  const MovieDetails({Key? key, required this.movieId}) : super(key: key);

  @override
  State<MovieDetails> createState() => _MovieDetailsState();
}

class _MovieDetailsState extends State<MovieDetails> {
  Map<String, dynamic>? movie;
  bool loading = true;
  bool error = false;

  final String apiKey = "791ce2b8dbmsh264a5de59c49373p1578a7jsn279cbd83e889";
  final String apiHost = "imdb236.p.rapidapi.com";

  @override
  void initState() {
    super.initState();
    fetchMovieDetails();
  }

  Future<void> fetchMovieDetails() async {
    try {
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
          loading = false;
        });
      } else {
        setState(() {
          error = true;
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = true;
        loading = false;
      });
    }
  }

  void _onPlaylistPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Add ${movie?['primaryTitle'] ?? 'movie'} to playlist'),
        backgroundColor: Colors.red,
      ),
    );
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
        return Container(
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            item.toString(),
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
    final trailerUrl = movie?['trailer'];
    final youtubeVideoId = trailerUrl != null ? _extractYouTubeVideoId(trailerUrl) : null;
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
                // YouTube thumbnail with play button overlay
                GestureDetector(
                  onTap: () => _launchTrailer(trailerUrl!),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // YouTube thumbnail
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
                      // Dark overlay
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
                      // Play button
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
                      // Duration badge (optional)
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
                // Trailer info and button
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.movie_rounded, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Official Trailer',
                              style: const TextStyle(
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
                          onPressed: () => _launchTrailer(trailerUrl!),
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
                        onPressed: () => _launchTrailer(trailerUrl!),
                        child: const Text(
                          'Open in browser',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // No trailer available
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
                          // Option to search for trailer
                          final movieTitle = movie?['primaryTitle'] ?? movie?['title'] ?? '';
                          if (movieTitle.isNotEmpty) {
                            final searchUrl = 'https://www.youtube.com/results?search_query=${Uri.encodeComponent('$movieTitle official trailer')}';
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

  // ... (keep all your existing methods: _buildCastMember, _buildCrewMember, etc.)

  Widget _buildCastMember(Map<String, dynamic> person) {
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
              image: person['primaryImage'] != null
                  ? DecorationImage(
                      image: NetworkImage(person['primaryImage']),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: Colors.grey[800],
              border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
            ),
            child: person['primaryImage'] == null
                ? const Icon(Icons.person, color: Colors.white54, size: 40)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            person['fullName'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          if (person['characters'] != null && person['characters'].isNotEmpty)
            Text(
              person['characters'][0],
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
              image: person['primaryImage'] != null
                  ? DecorationImage(
                      image: NetworkImage(person['primaryImage']),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: Colors.grey[800],
              border: Border.all(color: Colors.red.withOpacity(0.5), width: 1.5),
            ),
            child: person['primaryImage'] == null
                ? const Icon(Icons.person, color: Colors.white54, size: 30)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            person['fullName'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            _formatJobTitle(person['job']),
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

    // ... (keep the rest of your build method exactly as it was, just replace the _buildTrailerSection call)

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
              IconButton(
                onPressed: _onPlaylistPressed,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                movie!['primaryTitle'] ?? movie!['title'] ?? "No Title",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: movie!['primaryImage'] != null
                  ? Image.network(
                      movie!['primaryImage'],
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.3),
                      colorBlendMode: BlendMode.darken,
                    )
                  : Container(
                      color: Colors.grey[900],
                      child: const Icon(Icons.movie, color: Colors.white54, size: 64),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Your existing title section
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
                          movie!['primaryTitle'] ?? movie!['title'] ?? "No Title",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        if ((movie!['originalTitle'] ?? '') != (movie!['primaryTitle'] ?? movie!['title'] ?? '')) ...[
                          const SizedBox(height: 4),
                          Text(
                            movie!['originalTitle'],
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
                            _buildInfoChip(
                              Icons.star,
                              movie!['averageRating']?.toString() ?? "N/A",
                              'IMDb',
                              Colors.amber,
                            ),
                            const SizedBox(width: 12),
                            _buildInfoChip(
                              Icons.access_time,
                              '${movie!['runtimeMinutes']?.toString() ?? "N/A"} min',
                              'Duration',
                              Colors.blue,
                            ),
                            const SizedBox(width: 12),
                            _buildInfoChip(
                              Icons.calendar_today,
                              _getYear(_formatDate(movie!['releaseDate'])),
                              'Year',
                              Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Rating stats
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900]!.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildRatingStat('IMDb', movie!['averageRating']?.toString() ?? "N/A", Icons.star, Colors.amber),
                        _buildRatingStat('Metascore', movie!['metascore']?.toString() ?? "N/A", Icons.assessment, Colors.blue),
                        _buildRatingStat('Votes', movie!['numVotes'] != null ? _formatNumber(movie!['numVotes']) : "N/A", Icons.people, Colors.green),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // NEW: Trailer Section (reworked)
                  _buildTrailerSection(),
                  const SizedBox(height: 24),
                  // Continue with the rest of your existing sections...
                  _buildSectionTitle('Synopsis'),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900]!.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      movie!['description'] ?? movie!['plot'] ?? "No description available",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                  // ... (rest of your existing sections)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ... (keep all your existing helper methods: _buildInfoChip, _buildRatingStat, etc.)

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
              style: TextStyle(
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
    if (date == null) return "N/A";
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return "${parsedDate.day}/${parsedDate.month}/${parsedDate.year}";
    } catch (e) {
      return date;
    }
  }

  String _getYear(String date) {
    try {
      final parts = date.split('/');
      return parts.last;
    } catch (e) {
      return "N/A";
    }
  }

  String _formatNumber(dynamic number) {
    if (number is int) {
      if (number >= 1000000) {
        return '${(number / 1000000).toStringAsFixed(1)}M';
      } else if (number >= 1000) {
        return '${(number / 1000).toStringAsFixed(1)}K';
      }
      return number.toString();
    }
    return number.toString();
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
}