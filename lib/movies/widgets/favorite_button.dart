import 'package:flutter/material.dart';
import 'package:netmatch/services/favorites_service.dart';

class FavoriteButton extends StatefulWidget {
  final Map<String, dynamic> movie;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const FavoriteButton({
    Key? key,
    required this.movie,
    this.size = 24,
    this.activeColor = Colors.red,
    this.inactiveColor = Colors.white,
  }) : super(key: key);

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  final FavoritesService _favoritesService = FavoritesService();
  bool _isFavorite = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteStatus() async {
    final movieId = widget.movie['id'] ?? widget.movie['primaryTitle'] ?? '';
    if (movieId.isEmpty) return;

    final isFav = await _favoritesService.isFavorite(movieId);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final movieId = widget.movie['id'] ?? widget.movie['primaryTitle'] ?? '';

      if (_isFavorite) {
        await _favoritesService.removeFromFavorites(movieId);
        if (mounted) {
          setState(() {
            _isFavorite = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Removed from favorites'),
              backgroundColor: Colors.grey[850],
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        await _favoritesService.addToFavorites(widget.movie);
        if (mounted) {
          setState(() {
            _isFavorite = true;
          });
          _animationController.forward().then((_) {
            _animationController.reverse();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Added to favorites'),
              backgroundColor: Colors.grey[850],
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[900],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFavorite,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: widget.activeColor,
                ),
              )
                  : Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? widget.activeColor : widget.inactiveColor,
                size: widget.size,
              ),
            ),
          );
        },
      ),
    );
  }
}