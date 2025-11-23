import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  final String apiKey = "037bb2a6f2msh3318286b4442a19p1830dbjsn1c3768125ddc";
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipList(List<dynamic> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return Chip(
          label: Text(
            item.toString(),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.withOpacity(0.7),
        );
      }).toList(),
    );
  }

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
              fontWeight: FontWeight.w500,
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
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            person['job'],
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

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );
    }

    if (error || movie == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Failed to load movie details",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final title = movie!['primaryTitle'] ?? movie!['title'] ?? "No Title";
    final originalTitle = movie!['originalTitle'] ?? title;
    final imageUrl = movie!['primaryImage'];
    final rating = movie!['averageRating']?.toString() ?? "N/A";
    final description = movie!['description'] ?? movie!['plot'] ?? "No description";
    final runtime = movie!['runtimeMinutes']?.toString() ?? "N/A";
    final releaseDate = movie!['releaseDate'] ?? "N/A";
    final genres = movie!['genres'] ?? [];
    final countries = movie!['countriesOfOrigin'] ?? [];
    final languages = movie!['spokenLanguages'] ?? [];
    final budget = movie!['budget'] != null ? '\$${movie!['budget']}' : "N/A";
    final gross = movie!['grossWorldwide'] != null ? '\$${movie!['grossWorldwide']}' : "N/A";
    final metascore = movie!['metascore']?.toString() ?? "N/A";
    final numVotes = movie!['numVotes']?.toString() ?? "N/A";

    final directors = (movie!['directors'] ?? []).where((person) => person['job'] == 'director').toList();
    final writers = (movie!['writers'] ?? []).where((person) => person['job'] == 'writer').toList();
    final cast = (movie!['cast'] ?? []).where((person) => person['job'] == 'actor' || person['job'] == 'actress').toList();
    final crew = (movie!['cast'] ?? []).where((person) => 
        person['job'] == 'producer' || 
        person['job'] == 'composer' || 
        person['job'] == 'cinematographer' || 
        person['job'] == 'editor' || 
        person['job'] == 'production_designer' || 
        person['job'] == 'casting_director').toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      height: 200,
                      width: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (originalTitle != title)
                        Text(
                          originalTitle,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.red, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            rating,
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              movie!['contentRating'] ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$runtime minutes',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Released: $releaseDate',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Rating Info
            Row(
              children: [
                _buildRatingItem('IMDb Rating', rating, Icons.star),
                const SizedBox(width: 20),
                _buildRatingItem('Metascore', metascore, Icons.score),
                const SizedBox(width: 20),
                _buildRatingItem('Votes', numVotes, Icons.people),
              ],
            ),

            const SizedBox(height: 24),

            // Description
            _buildSectionTitle('Synopsis'),
            Text(
              description,
              style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
            ),

            const SizedBox(height: 24),

            // Genres
            if (genres.isNotEmpty) ...[
              _buildSectionTitle('Genres'),
              _buildChipList(genres),
              const SizedBox(height: 24),
            ],

            // Additional Info
            _buildSectionTitle('Details'),
            _buildInfoRow('Type', movie!['type']?.toString() ?? 'N/A'),
            _buildInfoRow('Countries', countries.join(', ')),
            _buildInfoRow('Languages', languages.join(', ')),
            _buildInfoRow('Budget', budget),
            _buildInfoRow('Worldwide Gross', gross),
            _buildInfoRow('Filming Locations', (movie!['filmingLocations'] ?? []).join(', ')),

            const SizedBox(height: 24),

            // Directors
            if (directors.isNotEmpty) ...[
              _buildSectionTitle('Directors'),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: directors.length,
                  itemBuilder: (context, index) {
                    return _buildCrewMember(directors[index]);
                  },
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
                  itemBuilder: (context, index) {
                    return _buildCrewMember(writers[index]);
                  },
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
                  itemBuilder: (context, index) {
                    return _buildCastMember(cast[index]);
                  },
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
                  itemBuilder: (context, index) {
                    return _buildCrewMember(crew[index]);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Production Companies
            if (movie!['productionCompanies'] != null && movie!['productionCompanies'].isNotEmpty) ...[
              _buildSectionTitle('Production Companies'),
              _buildChipList(movie!['productionCompanies'].map((company) => company['name']).toList()),
              const SizedBox(height: 24),
            ],

            // External Links
            if (movie!['externalLinks'] != null && movie!['externalLinks'].isNotEmpty) ...[
              _buildSectionTitle('Links'),
              Wrap(
                spacing: 8,
                children: movie!['externalLinks'].map<Widget>((link) {
                  return ActionChip(
                    label: Text(
                      _getLinkType(link),
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.blue.withOpacity(0.7),
                    onPressed: () {
                      // Handle link opening
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.red, size: 30),
          const SizedBox(height: 4),
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
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getLinkType(String url) {
    if (url.contains('facebook.com')) return 'Facebook';
    if (url.contains('twitter.com')) return 'Twitter';
    if (url.contains('youtube.com')) return 'YouTube';
    if (url.contains('instagram.com')) return 'Instagram';
    return 'Website';
  }
}