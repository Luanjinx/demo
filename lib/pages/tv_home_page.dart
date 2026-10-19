import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/section_model.dart';
import '../models/banner_model.dart';
import '../providers/tv_home_provider.dart';
import '../utils/color.dart';
import '../widgets/tv_banner.dart';
import '../widgets/tv_section_row.dart';
import '../widgets/tv_sidebar.dart';
import '../widgets/tv_focusable.dart';
import 'tv_details_page.dart';
import 'tv_login_page.dart';
import 'tv_search_page.dart';

class TVHomePage extends StatefulWidget {
  const TVHomePage({super.key});

  @override
  State<TVHomePage> createState() => _TVHomePageState();
}

class _TVHomePageState extends State<TVHomePage> {
  TVNavDestination _currentNav = TVNavDestination.home;
  final ScrollController _scrollController = ScrollController();

  void _onNavSelect(TVNavDestination destination) {
    final homeProvider = Provider.of<TVHomeProvider>(context, listen: false);

    setState(() {
      _currentNav = destination;
    });

    switch (destination) {
      case TVNavDestination.search:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TVSearchPage()),
        ).then((_) {
          setState(() {
            _currentNav = TVNavDestination.home;
          });
        });
        break;

      case TVNavDestination.login:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TVLoginPage()),
        ).then((_) {
          setState(() {
            _currentNav = TVNavDestination.home;
          });
        });
        break;

      case TVNavDestination.home:
        homeProvider.selectTab(0, "Beranda");
        _scrollToTop();
        break;

      case TVNavDestination.movies:
        _filterByType("Movie", "Film");
        _scrollToTop();
        break;

      case TVNavDestination.series:
        _filterByType("Show", "Serial / Drama");
        _scrollToTop();
        break;

      case TVNavDestination.anime:
        _filterByType("Anime", "Anime");
        _scrollToTop();
        break;
    }
  }

  void _filterByType(String keyword, String fallbackName) {
    final homeProvider = Provider.of<TVHomeProvider>(context, listen: false);
    final match = homeProvider.types.firstWhere(
      (t) => (t.name ?? '').toLowerCase().contains(keyword.toLowerCase()),
      orElse: () => homeProvider.types.isNotEmpty ? homeProvider.types.first : homeProvider.types.first,
    );
    homeProvider.selectTab(match.id ?? 0, match.name ?? fallbackName);
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _openDetails(ContentItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TVDetailsPage(
          id: item.id ?? 0,
          videoType: item.videoType ?? 1,
        ),
      ),
    );
  }

  void _openBannerDetails(BannerItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TVDetailsPage(
          id: item.id ?? 0,
          videoType: item.videoType ?? 1,
        ),
      ),
    );
  }

  void _playBanner(BannerItem item) {
    _openBannerDetails(item);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<TVHomeProvider>(context);

    return Scaffold(
      backgroundColor: TVColors.appBg,
      body: Row(
        children: [
          // 1. Android TV Sidebar Navigation
          TVSidebar(
            currentNav: _currentNav,
            onSelect: _onNavSelect,
          ),

          // 2. Main Content Area
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              clipBehavior: Clip.none,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Hero Banner
                  if (homeProvider.loadingBanners)
                    _buildBannerShimmer()
                  else if (homeProvider.banners.isNotEmpty)
                    TVBanner(
                      banners: homeProvider.banners,
                      onPlayTap: _playBanner,
                      onDetailTap: _openBannerDetails,
                    )
                  else
                    const SizedBox(height: 24),

                  // Horizontal Category Pills (Quick Switcher on top of sections)
                  if (homeProvider.types.isNotEmpty)
                    _buildCategoryPills(homeProvider),

                  // Horizontal Section Rows (Trending, Movies, Drama, Anime)
                  if (homeProvider.loadingSections)
                    _buildSectionsShimmer()
                  else if (homeProvider.sections.isNotEmpty)
                    ...homeProvider.sections.map(
                      (section) => TVSectionRow(
                        section: section,
                        onContentTap: _openDetails,
                      ),
                    )
                  else
                    _buildNoData(),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPills(TVHomeProvider provider) {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: provider.types.length + 1, // +1 for "Semua / Beranda"
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isHome = index == 0;
          final int typeId = isHome ? 0 : (provider.types[index - 1].id ?? 0);
          final String name = isHome ? "Semua" : (provider.types[index - 1].name ?? '');
          final bool isSelected = provider.selectedTypeId == typeId;

          return TVFocusable(
            onPressed: () {
              provider.selectTab(typeId, name);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? TVColors.primary : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? TVColors.primary : Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Text(
                name,
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
    );
  }

  Widget _buildBannerShimmer() {
    return Shimmer.fromColors(
      baseColor: TVColors.surfaceBg,
      highlightColor: TVColors.cardBg,
      child: Container(
        height: 380,
        width: double.infinity,
        color: TVColors.surfaceBg,
      ),
    );
  }

  Widget _buildSectionsShimmer() {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: TVColors.surfaceBg,
                highlightColor: TVColors.cardBg,
                child: Container(
                  width: 160,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (_, __) => Shimmer.fromColors(
                    baseColor: TVColors.surfaceBg,
                    highlightColor: TVColors.cardBg,
                    child: Container(
                      width: 135,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoData() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.movie_filter_outlined, color: TVColors.textMuted, size: 54),
            const SizedBox(height: 12),
            Text(
              "Belum ada konten pada kategori ini",
              style: GoogleFonts.outfit(
                color: TVColors.textMuted,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
