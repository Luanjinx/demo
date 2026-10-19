import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../models/section_model.dart';
import '../utils/color.dart';
import 'tv_focusable.dart';

enum TVCardLayout {
  portrait,
  landscape,
  indexPortrait,
  indexLandscape,
  square,
}

class TVCard extends StatelessWidget {
  final ContentItem item;
  final TVCardLayout layout;
  final int? indexRank;
  final VoidCallback onTap;

  const TVCard({
    super.key,
    required this.item,
    required this.layout,
    required this.onTap,
    this.indexRank,
  });

  bool get _isPortrait =>
      layout == TVCardLayout.portrait || layout == TVCardLayout.indexPortrait;

  double get _width {
    switch (layout) {
      case TVCardLayout.portrait:
      case TVCardLayout.indexPortrait:
        return 145.0;
      case TVCardLayout.landscape:
      case TVCardLayout.indexLandscape:
        return 240.0;
      case TVCardLayout.square:
        return 160.0;
    }
  }

  double get _height {
    switch (layout) {
      case TVCardLayout.portrait:
      case TVCardLayout.indexPortrait:
        return 215.0;
      case TVCardLayout.landscape:
      case TVCardLayout.indexLandscape:
        return 135.0;
      case TVCardLayout.square:
        return 160.0;
    }
  }

  String get _imageUrl {
    if (_isPortrait || layout == TVCardLayout.square) {
      return item.posterImage;
    }
    return item.backdropImage;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasRank = indexRank != null &&
        (layout == TVCardLayout.indexPortrait || layout == TVCardLayout.indexLandscape);

    return Container(
      margin: EdgeInsets.only(
        right: hasRank ? 24 : 14,
        left: hasRank ? 16 : 0,
        top: 8,
        bottom: 8,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          // Index Rank Number (Big Stylized Number behind/side)
          if (hasRank)
            Positioned(
              left: _isPortrait ? -22 : -26,
              bottom: -4,
              child: IgnorePointer(
                child: Text(
                  "${indexRank! + 1}",
                  style: GoogleFonts.blackOpsOne(
                    fontSize: _isPortrait ? 85 : 95,
                    fontWeight: FontWeight.w900,
                    color: Colors.transparent,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.9),
                        offset: const Offset(4, 4),
                        blurRadius: 8,
                      ),
                    ],
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 3.5
                      ..color = Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),

          // Focusable Card
          TVFocusable(
            onPressed: onTap,
            scaleFactor: 1.08,
            borderRadius: BorderRadius.circular(10),
            focusBorderColor: TVColors.focusBorder,
            focusGlowColor: TVColors.focusPrimaryGlow,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: _width,
                height: _height,
                color: TVColors.cardBg,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Poster / Backdrop Image
                    CachedNetworkImage(
                      imageUrl: _imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: TVColors.cardBg,
                        highlightColor: TVColors.surfaceBg,
                        child: Container(color: TVColors.cardBg),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: TVColors.surfaceBg,
                        child: const Center(
                          child: Icon(Icons.movie_outlined, color: TVColors.textMuted, size: 36),
                        ),
                      ),
                    ),

                    // Subtle Bottom Gradient
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 55,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.90),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Title Text
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 6,
                      child: Text(
                        item.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // VIP / Premium Badge
                    if ((item.isPremium ?? 0) == 1)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: TVColors.vipGold,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "VIP",
                            style: GoogleFonts.outfit(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),

                    // Rating Star Badge
                    if (item.avgRating != null &&
                        item.avgRating.toString() != "0" &&
                        item.avgRating.toString().isNotEmpty)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.70),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: TVColors.ratingStar, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                "${item.avgRating}",
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
