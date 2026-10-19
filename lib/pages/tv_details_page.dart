import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/detail_model.dart';
import '../models/section_model.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../webservice/api_service.dart';
import '../widgets/tv_card.dart';
import '../widgets/tv_focusable.dart';
import 'tv_player_page.dart';

class TVDetailsPage extends StatefulWidget {
  final int id;
  final int videoType;
  final int? typeId;
  final int subVideoType;
  final bool autoPlay;

  const TVDetailsPage({
    super.key,
    required this.id,
    required this.videoType,
    this.typeId,
    this.subVideoType = 0,
    this.autoPlay = false,
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

  List<ContentItem> _relatedContent = [];
  bool _isBookmarked = false;

  String get _selectedSeasonName {
    final seasons = _detail?.seasons ?? [];
    for (final s in seasons) {
      if (s.id == _selectedSeasonId) {
        return s.name ?? '';
      }
    }
    if (seasons.isNotEmpty) {
      return seasons.first.name ?? '';
    }
    return '';
  }

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
      typeId: widget.typeId ?? 0,
      subVideoType: widget.subVideoType,
    );

    if (mounted) {
      setState(() {
        _detail = res.result;
        _isLoading = false;
        _isBookmarked = (_detail?.isBookmark ?? 0) == 1;
      });

      if (_detail != null) {
        final effectiveVideoType = _detail?.videoType ?? widget.videoType;
        final effectiveTypeId = _detail?.typeId ?? widget.typeId ?? 0;
        final effectiveSubVideoType = _detail?.subVideoType ?? widget.subVideoType;

        // Fetch Related Content in parallel like dtlive-app
        _api.getRelatedContent(
          id: widget.id,
          videoType: effectiveVideoType,
          typeId: effectiveTypeId,
          subVideoType: effectiveSubVideoType,
        ).then((related) {
          if (mounted) {
            setState(() {
              _relatedContent = related;
            });
          }
        });

        // Load episodes for Shows / Shorts / Anime
        if (_detail?.seasons != null && _detail!.seasons!.isNotEmpty) {
          await _selectSeason(_detail!.seasons![0].id ?? 0);
        } else if (effectiveVideoType == Constant.videoTypeShorts) {
          await _loadShortsEpisodes();
        } else if (effectiveVideoType != Constant.videoTypeMovie) {
          await _selectSeason(0);
        }

        if (widget.autoPlay && mounted) {
          _playVideo();
        }
      }
    }
  }

  Future<void> _loadShortsEpisodes() async {
    setState(() {
      _loadingEpisodes = true;
    });

    final eps = await _api.getShortsEpisodes(shortsId: widget.id);

    if (mounted) {
      setState(() {
        _episodes = eps;
        _loadingEpisodes = false;
      });
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

  void _playVideo({
    String? customUrl,
    String? customTitle,
    int? epIndex,
    List<QualityOption>? qualities,
  }) {
    String url = (customUrl != null && customUrl.trim().isNotEmpty) ? customUrl.trim() : '';
    String title = customTitle ?? _detail?.displayName ?? '';
    List<QualityOption> qualityOptions = qualities ?? _detail?.qualities ?? [];

    if (url.isEmpty) {
      if (_episodes.isNotEmpty) {
        final firstEp = _episodes[0];
        url = firstEp.playableVideoUrl;
        title = "${_detail?.displayName} - ${firstEp.name ?? 'Episode 1'}";
        epIndex = 0;
        qualityOptions = firstEp.qualities;
      } else {
        url = _detail?.playableVideoUrl ?? '';
      }
    }

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.videoType == Constant.videoTypeMovie ? "Video belum tersedia" : "Episode belum tersedia",
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: TVColors.surfaceBg,
          behavior: SnackBarBehavior.floating,
        ),
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
          qualities: qualityOptions,
        ),
      ),
    );
  }

  void _playTrailer() {
    final trailer = _detail?.trailerUrl;
    if (trailer == null || trailer.trim().isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TVPlayerPage(
          videoUrl: trailer.trim(),
          title: "${_detail?.displayName ?? ''} (Trailer)",
          subtitle: "Trailer Resmi",
        ),
      ),
    );
  }

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isBookmarked ? "Ditambahkan ke Daftar Tonton" : "Dihapus dari Daftar Tonton",
          style: GoogleFonts.inter(color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: TVColors.surfaceBg,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: TVColors.appBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: TVColors.primary),
              const SizedBox(height: 18),
              Text(
                "Memuat detail konten...",
                style: GoogleFonts.inter(color: TVColors.textMuted, fontSize: 14),
              ),
            ],
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
              const Icon(Icons.error_outline_rounded, color: TVColors.accent, size: 52),
              const SizedBox(height: 14),
              Text(
                "Gagal memuat detail konten",
                style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                "Pastikan koneksi internet aktif atau coba beberapa saat lagi",
                style: GoogleFonts.inter(color: TVColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TVFocusable(
                    autoFocus: true,
                    onPressed: _loadDetails,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                      decoration: BoxDecoration(
                        color: TVColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text("Coba Lagi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  TVFocusable(
                    onPressed: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
                      ),
                      child: const Text("Kembali", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final d = _detail!;
    final effectiveVt = d.videoType ?? widget.videoType;
    final bool isTVShow = effectiveVt != Constant.videoTypeMovie;

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
                  TVColors.appBg.withValues(alpha: 0.88),
                  TVColors.appBg.withValues(alpha: 0.45),
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
                  const SizedBox(height: 20),

                  // Metadata Badges (Rating, Year, Duration, Category, ExoPlayer)
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
                                style: GoogleFonts.inter(
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
                      if (isTVShow && d.seasons != null && d.seasons!.isNotEmpty) ...[
                        _metaBadge("${d.seasons!.length} Season"),
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
                            style: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: TVColors.accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  const SizedBox(height: 18),

                  // Action Buttons: Play + Trailer + Watchlist
                  Row(
                    children: [
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
                            boxShadow: [
                              BoxShadow(
                                color: TVColors.primary.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                isTVShow ? "Mulai Menonton (Ep 1)" : "Tonton Film",
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Trailer Button
                      if (d.trailerUrl != null && d.trailerUrl!.isNotEmpty) ...[
                        TVFocusable(
                          onPressed: _playTrailer,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.movie_filter_outlined, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text("Trailer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                      ],

                      // Watchlist Button
                      TVFocusable(
                        onPressed: _toggleBookmark,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isBookmarked ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                                color: _isBookmarked ? TVColors.primary : Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isBookmarked ? "Tersimpan" : "Daftar Tonton",
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Synopsis
                  SizedBox(
                    width: 620,
                    child: Text(
                      d.description ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: TVColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Episodes Section (if TV Show / Drama / Anime / Shorts)
                  if (isTVShow) ...[
                    _buildSeasonsAndEpisodes(),
                    const SizedBox(height: 32),
                  ],

                  // Cast & Crew Section (like dtlive-app)
                  if (d.cast != null && d.cast!.isNotEmpty) ...[
                    _buildCastSection(d.cast!),
                    const SizedBox(height: 32),
                  ],

                  // Related Content (from get_releted_content API)
                  if (_relatedContent.isNotEmpty) ...[
                    _buildRelatedSection(_relatedContent),
                    const SizedBox(height: 20),
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
        style: GoogleFonts.inter(
          color: Colors.white70,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildCastSection(List<CastItem> castList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: TVColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "Pemeran & Kru",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: castList.length,
            separatorBuilder: (_, __) => const SizedBox(width: 18),
            itemBuilder: (context, index) {
              final cast = castList[index];
              return TVFocusable(
                onPressed: () {},
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 90,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(35),
                        child: Container(
                          width: 70,
                          height: 70,
                          color: TVColors.cardBg,
                          child: CachedNetworkImage(
                            imageUrl: cast.image ?? '',
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Icon(Icons.person_rounded, color: Colors.white54, size: 36),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cast.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        cast.type ?? 'Actor',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: TVColors.textMuted, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedSection(List<ContentItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: TVColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "Konten Serupa",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = items[index];
              return TVCard(
                item: item,
                layout: TVCardLayout.portrait,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TVDetailsPage(
                        id: item.id ?? 0,
                        videoType: item.videoType ?? widget.videoType,
                        typeId: item.typeId ?? widget.typeId ?? 0,
                        subVideoType: item.subVideoType ?? widget.subVideoType,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSeasonsAndEpisodes() {
    final seasons = _detail?.seasons ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Season Tabs (Always shown when series has season data)
        if (seasons.isNotEmpty) ...[
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: TVColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Musim / Season",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: seasons.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final s = seasons[index];
                final isSelected = s.id == _selectedSeasonId;

                return TVFocusable(
                  onPressed: () => _selectSeason(s.id ?? 0),
                  borderRadius: BorderRadius.circular(8),
                  scaleFactor: 1.05,
                  focusBorderColor: TVColors.primary,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? TVColors.primary : Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? TVColors.primary
                            : Colors.white.withValues(alpha: 0.18),
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: TVColors.primary.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(Icons.check_circle_rounded, color: Colors.black, size: 16),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          s.name ?? "Season ${index + 1}",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? Colors.black : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Episodes Header with current season name & count
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: TVColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "Daftar Episode",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (_selectedSeasonName.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                "• $_selectedSeasonName",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: TVColors.textSecondary,
                ),
              ),
            ],
            if (!_loadingEpisodes && _episodes.isNotEmpty) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${_episodes.length} Episode",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: TVColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        if (_loadingEpisodes)
          const Center(child: CircularProgressIndicator(color: TVColors.primary))
        else if (_episodes.isEmpty)
          Text(
            "Belum ada episode di season ini",
            style: GoogleFonts.inter(color: TVColors.textMuted, fontSize: 13),
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
                    customUrl: ep.playableVideoUrl,
                    customTitle: "${_detail?.displayName} - ${ep.name ?? 'Ep ${index + 1}'}",
                    epIndex: index,
                    qualities: ep.qualities,
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
                              style: GoogleFonts.inter(
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
