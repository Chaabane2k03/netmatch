import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class MoviesPage extends StatelessWidget {
  const MoviesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Movies Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),

            // Top Movies Section
            Text(
              'Top 3 Favorite Movies',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              flex: 2,
              child: TopMoviesSection(),
            ),

            SizedBox(height: 20),

            // Top Users Section
            Text(
              'Top Users Favoriting Movies',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              flex: 1,
              child: TopUsersSection(),
            ),
          ],
        ),
      ),
    );
  }
}

class TopMoviesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('favorites')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.red));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No favorites found', style: TextStyle(color: Colors.white)));
        }

        // Process data to get top movies
        final favorites = snapshot.data!.docs;
        final movieCounts = <String, int>{};
        final movieData = <String, Map<String, dynamic>>{};

        for (final doc in favorites) {
          final data = doc.data() as Map<String, dynamic>;
          final movieId = data['moviefd'] ?? '';
          final title = data['originalTitle'] ?? 'Unknown Movie';
          final image = data['primaryImage'] ?? '';
          final rating = data['averageRating'] ?? 0;
          final genres = List<String>.from(data['genres'] ?? []);

          movieCounts[movieId] = (movieCounts[movieId] ?? 0) + 1;

          if (!movieData.containsKey(movieId)) {
            movieData[movieId] = {
              'title': title,
              'image': image,
              'rating': rating,
              'genres': genres,
              'count': 0,
            };
          }
          movieData[movieId]!['count'] = movieCounts[movieId]!;
        }

        // Sort by count and take top 3
        final topMovies = movieData.entries.toList()
          ..sort((a, b) => b.value['count'].compareTo(a.value['count']))
          ..take(3);

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: topMovies.length,
          itemBuilder: (context, index) {
            final movie = topMovies[index];
            final data = movie.value;

            return Container(
              width: 200,
              margin: EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[900],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Movie Poster
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      image: DecorationImage(
                        image: NetworkImage(data['image'] ?? ''),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Movie Info
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'] ?? 'Unknown',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.yellow, size: 16),
                            SizedBox(width: 4),
                            Text(
                              '${data['rating']}%',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${data['count']} favorites',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Wrap(
                          children: (data['genres'] as List<String>).take(2).map((genre) {
                            return Container(
                              margin: EdgeInsets.only(right: 4, bottom: 4),
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                genre,
                                style: TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class TopUsersSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('favorites')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.red));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No users found', style: TextStyle(color: Colors.white)));
        }

        // Count favorites per user
        final favorites = snapshot.data!.docs;
        final userCounts = <String, int>{};

        for (final doc in favorites) {
          final data = doc.data() as Map<String, dynamic>;
          final userId = data['userId'] ?? '';
          userCounts[userId] = (userCounts[userId] ?? 0) + 1;
        }

        // Sort by count and take top users
        final topUsers = userCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value))
          ..take(5);

        return ListView.builder(
          itemCount: topUsers.length,
          itemBuilder: (context, index) {
            final user = topUsers[index];

            return Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  // User Avatar
                  CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Text(
                      'U${index + 1}',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 12),

                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User ${user.key.substring(0, 8)}...',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${user.value} favorites',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Rank Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRankColor(index),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0: return Colors.amber;
      case 1: return Colors.grey;
      case 2: return Colors.brown;
      default: return Colors.grey[800]!;
    }
  }
}