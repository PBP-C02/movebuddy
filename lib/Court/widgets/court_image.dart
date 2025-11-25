// lib/court/widgets/court_image.dart

import 'package:flutter/material.dart';

class CourtImage extends StatefulWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool showPlaceholder;
  final Widget? placeholderWidget;
  final Color? placeholderColor;
  final IconData? placeholderIcon;
  final double? placeholderIconSize;

  const CourtImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.showPlaceholder = true,
    this.placeholderWidget,
    this.placeholderColor,
    this.placeholderIcon,
    this.placeholderIconSize,
  });

  @override
  State<CourtImage> createState() => _CourtImageState();
}

class _CourtImageState extends State<CourtImage> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.imageUrl == null || widget.imageUrl!.isEmpty
            ? _buildPlaceholder()
            : Stack(
                children: [
                  Image.network(
                    widget.imageUrl!,
                    width: widget.width,
                    height: widget.height,
                    fit: widget.fit,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return _buildLoadingIndicator(loadingProgress);
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _buildErrorPlaceholder();
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingIndicator(ImageChunkEvent loadingProgress) {
    final progress = loadingProgress.expectedTotalBytes != null
        ? loadingProgress.cumulativeBytesLoaded /
            loadingProgress.expectedTotalBytes!
        : null;

    return Container(
      color: widget.placeholderColor ?? const Color(0xFFF1F5F9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 3,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFCBED98),
                ),
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 12),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    if (widget.placeholderWidget != null) {
      return widget.placeholderWidget!;
    }

    return Container(
      color: widget.placeholderColor ?? const Color(0xFFF1F5F9),
      child: Center(
        child: Icon(
          widget.placeholderIcon ?? Icons.sports_tennis,
          size: widget.placeholderIconSize ?? 64,
          color: const Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: widget.placeholderColor ?? const Color(0xFFF1F5F9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: widget.placeholderIconSize ?? 64,
              color: const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gambar tidak dapat dimuat',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cached version dengan animasi fade-in
class CourtImageCached extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CourtImageCached({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: imageUrl == null || imageUrl!.isEmpty
          ? _buildPlaceholder()
          : FadeInImage.assetNetwork(
              placeholder: 'assets/images/placeholder.png',
              image: imageUrl!,
              width: width,
              height: height,
              fit: fit,
              fadeInDuration: const Duration(milliseconds: 300),
              fadeOutDuration: const Duration(milliseconds: 100),
              imageErrorBuilder: (context, error, stackTrace) {
                return _buildErrorPlaceholder();
              },
            ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(
          Icons.sports_tennis,
          size: 64,
          color: Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(
          Icons.broken_image,
          size: 64,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}

/// Hero animation version untuk transisi smooth
class CourtImageHero extends StatelessWidget {
  final String heroTag;
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CourtImageHero({
    super.key,
    required this.heroTag,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
      child: CourtImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Zoomable version untuk detail view
class CourtImageZoomable extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CourtImageZoomable({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (imageUrl != null && imageUrl!.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _FullScreenImage(imageUrl: imageUrl!),
            ),
          );
        }
      },
      child: CourtImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Full screen image viewer
class _FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image,
                      size: 80,
                      color: Colors.white54,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Gambar tidak dapat dimuat',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
