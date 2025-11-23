import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
          'About Us',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Logo/Header
            Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset('assets/logos/logo.png'),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Netmatch',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // About Section
            _SectionContainer(
              title: 'About',
              child: const Text(
                'Netmatch is your ultimate destination for streaming movies and TV shows. '
                    'We offer a vast library of content across all genres, from classic films to the latest releases. '
                    'Our mission is to bring entertainment to everyone, anywhere, anytime.\n\n'
                    'With personalized recommendations, and multiple viewing profiles, '
                    'Netmatch ensures a seamless streaming experience for the whole family.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),

            // Mission Section
            _SectionContainer(
              title: 'Our Mission',
              child: const Text(
                'To revolutionize how people discover and enjoy entertainment by providing '
                    'unlimited access to quality content while making it accessible, affordable, '
                    'and enjoyable for everyone around the world.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),

            // Features Section
            _SectionContainer(
              title: 'Key Features',
              child: Column(
                children: const [
                  _FeatureItem(
                    icon: Icons.movie_creation,
                    title: 'Unlimited Films/TV Shows',
                    description: 'Watch thousands of movies and TV shows',
                  ),
                  _FeatureItem(
                    icon: Icons.download,
                    title: 'Customise Profile',
                    description: 'Manage your movie preferences and the avatar',
                  ),
                  _FeatureItem(
                    icon: Icons.people,
                    title: 'Multiple friends',
                    description: 'Discover new content with your friends based on your preferences',
                  ),
                  _FeatureItem(
                    icon: Icons.hd,
                    title: 'The Wikipedia of movies',
                    description: 'Crystal clear movie informations with possibility to watch the trailer',
                  ),

                ],
              ),
            ),

            // Team Section
            _SectionContainer(
              title: 'Our Team',
              child: Column(
                children: const [
                  _TeamMember(
                    name: 'Chaabane BOUSSADIA',
                    role: 'IGL4',
                    icon: Icons.person,
                  ),
                  _TeamMember(
                    name: 'Abderrahmen JEDIDI',
                    role: 'IGL4',
                    icon: Icons.person,
                  ),
                  _TeamMember(
                    name: 'Raed BETTAHER',
                    role: 'IGL4',
                    icon: Icons.person,
                  )
                ],
              ),
            ),

            // Contact Section
            _SectionContainer(
              title: 'Contact Us',
              child: Column(
                children: [
                  _ContactCard(
                    icon: Icons.email,
                    title: 'Email',
                    value: 'support@netmatch.tn',
                    onTap: () => _launchEmail('support@netmatch.tn'),
                  ),
                  const SizedBox(height: 12),
                  _ContactCard(
                    icon: Icons.phone,
                    title: 'Phone',
                    value: '+1 (800) 123-4567',
                    onTap: () => _launchPhone('+18001234567'),
                  ),
                  const SizedBox(height: 12),
                  _ContactCard(
                    icon: Icons.language,
                    title: 'Website',
                    value: 'www.movieflix.com',
                    onTap: () => _launchURL('https://www.movieflix.com'),
                  ),
                ],
              ),
            ),

            // Social Media Section
            _SectionContainer(
              title: 'Follow Us',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialButton(
                    icon: Icons.facebook,
                    onTap: () => _launchURL('https://facebook.com/movieflix'),
                  ),
                  const SizedBox(width: 16),
                  _SocialButton(
                    icon: Icons.camera_alt,
                    onTap: () => _launchURL('https://instagram.com/movieflix'),
                  ),
                  const SizedBox(width: 16),
                  _SocialButton(
                    icon: Icons.share,
                    onTap: () => _launchURL('https://twitter.com/movieflix'),
                  ),
                  const SizedBox(width: 16),
                  _SocialButton(
                    icon: Icons.play_arrow,
                    onTap: () => _launchURL('https://youtube.com/movieflix'),
                  ),
                ],
              ),
            ),

            // Legal Section
            _SectionContainer(
              title: 'Legal',
              child: Column(
                children: [
                  _LegalLink(
                    title: 'Terms of Service',
                    onTap: () {
                      // Navigate to terms of service
                    },
                  ),
                  _LegalLink(
                    title: 'Privacy Policy',
                    onTap: () {
                      // Navigate to privacy policy
                    },
                  ),
                  _LegalLink(
                    title: 'Cookie Policy',
                    onTap: () {
                      // Navigate to cookie policy
                    },
                  ),
                  _LegalLink(
                    title: 'License Agreement',
                    onTap: () {
                      // Navigate to license agreement
                    },
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Divider(color: Color(0xFF2D2D2D)),
                  const SizedBox(height: 20),
                  const Text(
                    '© 2024 MovieFlix. All rights reserved.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Made with ❤️ for movie lovers worldwide',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  static Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  static Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _SectionContainer extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionContainer({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.red, size: 24),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamMember extends StatelessWidget {
  final String name;
  final String role;
  final IconData icon;

  const _TeamMember({
    required this.name,
    required this.role,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.red.withOpacity(0.2),
            child: Icon(icon, color: Colors.red, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  role,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.red, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.red, size: 28),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _LegalLink({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}