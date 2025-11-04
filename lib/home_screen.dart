import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HomeScreen extends StatelessWidget {

  final List<String> imgList = [
    'https://images.unsplash.com/photo-1520342868574-5fa3804e551c',
    'https://images.unsplash.com/photo-1522205408450-add114ad53fe',
    'https://images.unsplash.com/photo-1559827260-dc66d52bef19',
  ];

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(
        height: 400.0,
        autoPlay: true,
        enlargeCenterPage: true,
      ),
      items: imgList.map((item) => Container(
        child: Center(
          child: Image.network(item, fit: BoxFit.cover, width: 1000),
        ),
      )).toList(),
    );
  }
}