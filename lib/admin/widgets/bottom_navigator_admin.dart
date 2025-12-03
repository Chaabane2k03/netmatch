import 'package:flutter/material.dart';
import 'package:netmatch/profile/edit_profile.dart';

import '../movies/crudmovies.dart';
import '../movies/movies_management.dart';
import '../user/user_management.dart';

class AdminBottomNavigation extends StatefulWidget {
  const AdminBottomNavigation({Key? key}) : super(key: key);

  @override
  State<AdminBottomNavigation> createState() => _AdminBottomNavigationState();
}

class _AdminBottomNavigationState extends State<AdminBottomNavigation> {
  int _selectedIndex = 0;

  // Pages for each tab
  final List<Widget> _pages = [
    const UsersPage(),
    const MoviesPage(),
    ManageMoviesPage(),
    const MyAccountPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.movie),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Image.asset("assets/logos/logo.png" , height:50 , width:50),
            label:"Movies"
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFE50914), // Netflix red
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFF141414), // Dark background
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}



