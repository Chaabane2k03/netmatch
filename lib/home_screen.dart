import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:netmatch/auth/authScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<HomeScreen> {
  final CarouselSliderController _carouselController = CarouselSliderController();
  int _currentIndex = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      image: 'assets/images/onboarding1.png',
      title: 'Unlimited Movies & Series',
      description: 'Stream thousands of exclusive titles anytime, anywhere on all your devices',
      color: Colors.red,
    ),
    OnboardingItem(
      image: 'assets/images/onboarding2.png',
      title: 'Download & Watch Offline',
      description: 'Enjoy your favorite content even without internet connection',
      color: Colors.purple,
    ),
    OnboardingItem(
      image: 'assets/images/onboarding3.png',
      title: 'Premium & Modern',
      description: 'Find movie lovers who match your taste—instantly, beautifully',
      color: Colors.blue,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // FULLSCREEN BACKGROUND IMAGE CAROUSEL
          Positioned.fill(
            child: CarouselSlider.builder(
              carouselController: _carouselController,
              itemCount: _items.length,
              options: CarouselOptions(
                height: size.height,
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
                autoPlay: false,
                onPageChanged: (index, reason) {
                  setState(() => _currentIndex = index);
                },
              ),
              itemBuilder: (context, index, realIndex) {
                return Image.asset(
                  _items[index].image,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),

          // OVERLAY GRADIENT
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.8),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),

          // CONTENT LAYER
          SafeArea(
            child: Column(
              children: [
                // Skip Button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, right: 20),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const MainScreen()),
                        );
                      },
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _items[_currentIndex].title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _items[_currentIndex].description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 18,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_items.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentIndex == index ? 32 : 12,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentIndex == index ? Colors.red : Colors.white54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 40),

                // Navigation Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous Button
                      if (_currentIndex > 0)
                        ElevatedButton(
                          onPressed: () => _carouselController.previousPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOutCubic,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.15),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Row(
                            children: [Icon(Icons.arrow_back_rounded), SizedBox(width: 8), Text('Previous')],
                          ),
                        )
                      else
                        const SizedBox(width: 120),

                      // Next / Get Started
                      ElevatedButton(
                        onPressed: () {
                          if (_currentIndex < _items.length - 1) {
                            _carouselController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOutCubic,
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const MainScreen()),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          children: [
                            Text(_currentIndex == _items.length - 1 ? 'Get Started' : 'Next'),
                            const SizedBox(width: 8),
                            Icon(_currentIndex == _items.length - 1 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class OnboardingItem {
  final String image;
  final String title;
  final String description;
  final Color color;

  OnboardingItem({
    required this.image,
    required this.title,
    required this.description,
    required this.color,
  });
}

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Authscreen();
  }
}
