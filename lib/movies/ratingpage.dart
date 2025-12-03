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
        "x-rapidapi-key": "30da5f7584mshaa399720f74916ep1f44b6jsn5a241833e23a",
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
