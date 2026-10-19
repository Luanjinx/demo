import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../models/detail_model.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../webservice/api_service.dart';
import '../widgets/tv_card.dart';
import '../widgets/tv_focusable.dart';
import 'tv_player_page.dart';

class TVDetailsPage extends StatefulWidget {
  final int id;
  final int videoType;

  const TVDetailsPage({
    super.key,
    required this.id,
    required this.videoType,
  });

  @override
  State<TVDetailsPage> createState() => _TVDetailsPageState();
}

class _TVDetailsPageState extends State<TVDetailsPage> {
  final TVApiService _api = TVApiService();
  DetailResult? _detail;
  bool _isLoading = true;

  int _selectedSeasonId = 0;
  List<EpisodeItem> _episodes = [];
  bool _loadingEpisodes = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
    });

    final res = await _api.getContentDetail(
      id: widget.id,
      videoType: widget.videoType,
    );

    if (mounted) {
      setState(() {
        _detail = res.result;
        _isLoading = false;
      });

      // If TV Show has seasons, load first season's episodes
      if (_detail?.seasons != null && _detail!.seasons!.isNotEmpty) {
        _selectSeason(_detail!.seasons![0].id ?? 0);
      }
    }
  }

  Future<void> _selectSeason(int seasonId) async {
    setState(() {
      _selectedSeasonId = seasonId;
      _loadingEpisodes = true;
    });

    final eps = await _api.getEpisodesBySeason(
      showId: widget.id,
      seasonId: seasonId,
    );

    if (mounted) {
      setState(() {
        _episodes = eps;
        _loadingEpisodes = false;
      });
    }
  }

  void _playVideo({String? customUrl, String? customTitle, int? epIndex}) {
    final url = customUrl ?? _detail?.videoUrl ?? '';
    final title = customTitle ?? _detail?.displayName ?? '';

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Video belum tersedia")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TVPlayerPage(
          videoUrl: url,
          title: title,
          subtitle: _detail?.categoryName,
          episodes: _episodes,
          currentEpisodeIndex: epIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: TVColors.appBg,
        body: Center(
          child: Shimmer.fromColors(
            baseColor: TVColors.surfaceBg,
            highlightColor: TVColors.cardBg,
            child: Container(
              width: 120,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      );
    }

    if (_detail == null) {
      return Scaffold(
        backgroundColor: TVColors.appBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: TVColors.textMuted, size: 48),
              const SizedBox(height: 12),
              Text(
                "Gagal memuat detail konten",
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 16),
              TVFocusable(
                onPressed: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: TVColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text("Kembali", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final d = _detail!;
    final bool isTVShow = widget.videoType != Constant.videoTypeMovie;

    return Scaffold(
      backgroundColor: TVColors.appBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Backdrop Image
          CachedNetworkImage(
            imageUrl: d.backdropImage,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorWidget: (_, __, ___) => Container(color: TVColors.appBg),
          ),

          // Gradients
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  TVColors.appBg.withValues(alpha: 0.98),
                  TVColors.appBg.withValues(alpha: 0.85),
                  TVColors.appBg.withValues(alpha: 0.40),
                  TVColors.appBg.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.45, 0.80, 1.0],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  TVColors.appBg.withValues(alpha: 0.60),
                  Colors.transparent,
                  TVColors.appBg.withValues(alpha: 0.95),
                  TVColors.appBg,
                ],
                stops: const [0.0, 0.35, 0.70, 1.0],
              ),
            ),
          ),

          // Main Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  TVFocusable(
                    onPressed: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Metadata Badges (Rating, Year, Duration, Category)
                  Row(
                    children: [
                      if (d.avgRating != null && d.avgRating.toString() != "0") ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: TVColors.ratingStar.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: TVColors.ratingStar, width: 0.8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, color: TVColors.ratingStar, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                "${d.avgRating}",
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (d.releaseYear != null && d.releaseYear!.isNotEmpty) ...[
                        _metaBadge(d.releaseYear!),
                        const SizedBox(width: 10),
                      ],
                      if (d.duration != null && d.duration!.isNotEmpty) ...[
                        _metaBadge(d.duration!),
                        const SizedBox(width: 10),
                      ],
                      if ((d.isPremium ?? 0) == 1) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: TVColors.vipGold,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "VIP",
                            style: GoogleFonts.outfit(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      _metaBadge("HD"),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  SizedBox(
                    width: 580,
                    child: Text(
                      d.displayName,
                      style: GoogleFonts.outfit(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Category
                  if (d.categoryName != null && d.categoryName!.isNotEmpty)
                    Text(
                      d.categoryName!,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: TVColors.accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Play Button
                  TVFocusable(
                    autoFocus: true,
                    onPressed: () => _playVideo(),
                    borderRadius: BorderRadius.circular(8),
                    focusBorderColor: Colors.white,
                    focusGlowColor: TVColors.focusPrimaryGlow,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                      decoration: BoxDecoration(
                        color: TVColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            isTVShow ? "Mulai Menonton (Ep 1)" : "Tonton Film",
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Synopsis
                  SizedBox(
                    width: 600,
                    child: Text(
                      d.description ?? '',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: TVColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Episodes Section (if TV Show / Drama / Anime)
                  if (isTVShow) ...[
                    _buildSeasonsAndEpisodes(),
                    const SizedBox(height: 36),
                  ],

                  // Related Content
                  if (d.relatedContent != null && d.relatedContent!.isNotEmpty) ...[
                    Text(
                      "Konten Serupa",
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: d.relatedContent!.length,
                        itemBuilder: (context, index) {
                          final item = d.relatedContent![index];
                          return TVCard(
                            item: item,
                            layout: TVCardLayout.portrait,
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TVDetailsPage(
                                    id: item.id ?? 0,
                                    videoType: item.videoType ?? 1,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: Colors.white70,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildSeasonsAndEpisodes() {
    final seasons = _detail?.seasons ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Season Tabs
        if (seasons.length > 1)
          Container(
            height: 36,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: seasons.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final s = seasons[index];
                final isSelected = s.id == _selectedSeasonId;

                return TVFocusable(
                  onPressed: () => _selectSeason(s.id ?? 0),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? TVColors.primary : Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      s.name ?? "Season ${index + 1}",
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        Text(
          "Daftar Episode",
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        if (_loadingEpisodes)
          const Center(child: CircularProgressIndicator(color: TVColors.primary))
        else if (_episodes.isEmpty)
          Text(
            "Belum ada episode di season ini",
            style: GoogleFonts.outfit(color: TVColors.textMuted, fontSize: 13),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: _episodes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final ep = _episodes[index];
                final img = (ep.landscape != null && ep.landscape!.isNotEmpty)
                    ? ep.landscape!
                    : (ep.thumbnail ?? _detail?.backdropImage ?? '');

                return TVFocusable(
                  onPressed: () => _playVideo(
                    customUrl: ep.videoUrl,
                    customTitle: "${_detail?.displayName} - ${ep.name ?? 'Ep ${index + 1}'}",
                    epIndex: index,
                  ),
                  scaleFactor: 1.08,
                  borderRadius: BorderRadius.circular(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 220,
                      height: 135,
                      color: TVColors.cardBg,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: img,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(color: TVColors.surfaceBg),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.85),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            bottom: 8,
                            right: 10,
                            child: Text(
                              ep.name ?? "Episode ${index + 1}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
