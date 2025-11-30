import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RatingPage extends StatefulWidget {
  @override
  _RatingPageState createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  Map<String, dynamic>? ratingData;

  @override
  void initState() {
    super.initState();
    fetchRating();
  }

  Future<void> fetchRating() async {
    final url = Uri.parse(
        "https://imdb236.p.rapidapi.com/api/imdb/tt0816692/rating");

    final response = await http.get(
      url,
      headers: {
        "x-rapidapi-key": "15eac98273msh04a9da2a56942f2p17dcc2jsn41c6c8689c66",
        "x-rapidapi-host": "imdb236.p.rapidapi.com",
      },
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {
      setState(() {
        ratingData = jsonDecode(response.body);
      });
    } else {
      print("Failed: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Movie Rating")),
      body: ratingData == null
          ? Center(child: CircularProgressIndicator())
          : Center(
        child: Text(
          "Rating: ${ratingData!['averageRating']}",
          style: TextStyle(fontSize: 24),
        ),
      ),

    );
  }
}
