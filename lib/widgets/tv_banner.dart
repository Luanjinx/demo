import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/banner_model.dart';
import '../utils/color.dart';
import 'tv_focusable.dart';

class TVBanner extends StatefulWidget {
  final List<BannerItem> banners;
  final Function(BannerItem item) onPlayTap;
  final Function(BannerItem item) onDetailTap;

  const TVBanner({
    super.key,
    required this.banners,
    required this.onPlayTap,
    required this.onDetailTap,
  });

  @override
  State<TVBanner> createState() => _TVBannerState();
}

class _TVBannerState extends State<TVBanner> {
  final CarouselSliderController _carouselController = CarouselSliderController();
  int _currentIndex = 0;
  bool _isPaused = false;

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    final screenH = MediaQuery.of(context).size.height;
    final bannerH = (screenH * 0.62).clamp(340.0, 480.0);
    final activeItem = widget.banners[_currentIndex];

    return SizedBox(
      height: bannerH,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Carousel Slider (Backdrop)
          CarouselSlider.builder(
            carouselController: _carouselController,
            itemCount: widget.banners.length,
            options: CarouselOptions(
              height: bannerH,
              viewportFraction: 1.0,
              autoPlay: !_isPaused && widget.banners.length > 1,
              autoPlayInterval: const Duration(seconds: 7),
              autoPlayAnimationDuration: const Duration(milliseconds: 900),
              autoPlayCurve: Curves.easeInOutCubic,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
            itemBuilder: (context, index, realIndex) {
              final item = widget.banners[index];
              return CachedNetworkImage(
                imageUrl: item.bannerImage,
                fit: BoxFit.cover,
                width: double.infinity,
                height: bannerH,
                errorWidget: (_, __, ___) => Container(color: TVColors.surfaceBg),
              );
            },
          ),

          // Left-to-Right and Top-to-Bottom Cinematic Gradients
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  TVColors.appBg.withValues(alpha: 0.96),
                  TVColors.appBg.withValues(alpha: 0.80),
                  TVColors.appBg.withValues(alpha: 0.20),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.40, 0.75, 1.0],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  TVColors.appBg.withValues(alpha: 0.50),
                  Colors.transparent,
                  TVColors.appBg.withValues(alpha: 0.90),
                  TVColors.appBg,
                ],
                stops: const [0.0, 0.30, 0.75, 1.0],
              ),
            ),
          ),

          // Content Metadata & Remote Action Buttons
          Positioned(
            left: 32,
            bottom: 30,
            width: 480,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category Tags
                if (activeItem.categoryName != null && activeItem.categoryName!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
                    ),
                    child: Text(
                      activeItem.categoryName!.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: TVColors.accent,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),

                // Title
                Text(
                  activeItem.name ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Synopsis
                Text(
                  activeItem.description ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: TVColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // TV Action Buttons (Focused via Remote D-pad)
                Row(
                  children: [
                    // Play Button
                    TVFocusable(
                      onFocusChanged: (focused) {
                        setState(() {
                          _isPaused = focused;
                        });
                      },
                      onPressed: () => widget.onPlayTap(activeItem),
                      borderRadius: BorderRadius.circular(8),
                      focusBorderColor: Colors.white,
                      focusGlowColor: TVColors.focusPrimaryGlow,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        decoration: BoxDecoration(
                          color: TVColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              "Tonton Sekarang",
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Detail Button
                    TVFocusable(
                      onFocusChanged: (focused) {
                        setState(() {
                          _isPaused = focused;
                        });
                      },
                      onPressed: () => widget.onDetailTap(activeItem),
                      borderRadius: BorderRadius.circular(8),
                      focusBorderColor: Colors.white,
                      focusGlowColor: TVColors.focusGlow,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.30), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "Detail",
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
