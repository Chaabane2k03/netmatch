import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:netmatch/auth/loginScreen.dart';
import 'dart:typed_data';
import 'dart:convert';

import 'package:netmatch/profile/fields/edit_password.dart';

import 'fields/edit_avatar.dart';
import 'fields/about_us.dart';
import 'fields/edit_preferences.dart';

class MyAccountPage extends StatelessWidget {
  const MyAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Account',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.red),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'No user data found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Avatar Section
                AccountListTile(
                  title: 'Avatar',
                  trailing: CircleAvatar(
                    radius: 30,
                    backgroundImage: userData['profileImageBase64'] != null
                        ? MemoryImage(_decodeBase64(userData['profileImageBase64']))
                        : null,
                    backgroundColor: Colors.grey[800],
                    child: userData['profileImageBase64'] == null
                        ? const Icon(Icons.person, size: 30, color: Colors.white)
                        : null,
                  ),
                  onTap: () {
                    // Navigate to avatar selection
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChangeAvatarPage())
                    );
                  },
                ),

                // Username Section
                AccountListTile(
                  title: 'Username',
                  subtitle: userData['fullName'] ?? 'N/A',
                  onTap: () {
                    // Navigate to username edit
                  },
                ),


                // Email Section
                AccountListTile(
                  title: 'Email',
                  subtitle: userData['email'] ?? user?.email ?? 'N/A',
                ),

                // Movie Preferences Section
                AccountListTile(
                  title: 'Movie Preferences',
                  subtitle: userData['moviePreferences'] != null
                      ? (userData['moviePreferences'] as List).join(', ')
                      : 'Not set',
                  onTap: () {
                    // Navigate to movie preferences
                    Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const MoviePreferencesPage())
                    );
                  },
                ),

                // Account Security Section
                AccountListTile(
                  title: 'Account Security',
                  onTap: () {
                    // Navigate to account security
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChangePasswordPage())
                    );
                  },
                ),

                AccountListTile(
                  title: 'About Us',
                  onTap: () {
                    // Navigate to account security
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AboutUsPage())
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Sign Out Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: OutlinedButton(
                    onPressed: () => _signOut(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper method to decode base64 image
  Uint8List _decodeBase64(String base64String) {
    try {
      // Remove data:image prefix if present
      final base64Data = base64String.split(',').last;
      return base64Decode(base64Data);
    } catch (e) {
      print('Error decoding base64: $e');
      return Uint8List(0);
    }
  }


  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => LoginPage())
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Custom List Tile Widget
class AccountListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showArrow;

  const AccountListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFF2D2D2D), width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (showArrow)
              const Icon(
                Icons.chevron_right,
                color: Colors.white54,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}