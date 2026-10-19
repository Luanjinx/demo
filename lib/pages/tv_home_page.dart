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
import 'tv_details_page.dart';
import 'tv_login_page.dart';
import 'tv_search_page.dart';

class TVHomePage extends StatefulWidget {
  const TVHomePage({super.key});

  @override
  State<TVHomePage> createState() => _TVHomePageState();
}

class _TVHomePageState extends State<TVHomePage> {
  String _currentNavKey = 'home';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeProvider = Provider.of<TVHomeProvider>(context, listen: false);
      if (homeProvider.types.isEmpty && !homeProvider.loadingTypes) {
        homeProvider.initHome();
      }
    });
  }

  void _onNavSelect(String navKey, {int? typeId, String? typeName}) {
    final homeProvider = Provider.of<TVHomeProvider>(context, listen: false);

    if (navKey == 'search') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TVSearchPage()),
      );
      return;
    }

    if (navKey == 'login') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TVLoginPage()),
      );
      return;
    }

    setState(() {
      _currentNavKey = navKey;
    });

    if (navKey == 'home') {
      homeProvider.selectTab(0, "Beranda");
      _scrollToTop();
    } else if (typeId != null) {
      homeProvider.selectTab(typeId, typeName ?? "");
      _scrollToTop();
    }
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

  void _openDetails(ContentItem item, [SectionItem? section]) {
    final effectiveVideoType = (item.videoType != null && item.videoType != 0)
        ? item.videoType!
        : ((section?.videoType != null && section!.videoType != 0) ? section.videoType! : 1);
    final effectiveTypeId = (item.typeId != null && item.typeId != 0)
        ? item.typeId!
        : ((section?.typeId != null && section!.typeId != 0) ? section.typeId! : 0);
    final effectiveSubVideoType = (item.subVideoType != null && item.subVideoType != 0)
        ? item.subVideoType!
        : (section?.subVideoType ?? 0);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TVDetailsPage(
          id: item.id ?? 0,
          videoType: effectiveVideoType,
          typeId: effectiveTypeId,
          subVideoType: effectiveSubVideoType,
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
          typeId: item.typeId ?? 0,
          subVideoType: item.subVideoType ?? 0,
        ),
      ),
    );
  }

  void _playBanner(BannerItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TVDetailsPage(
          id: item.id ?? 0,
          videoType: item.videoType ?? 1,
          typeId: item.typeId ?? 0,
          subVideoType: item.subVideoType ?? 0,
          autoPlay: true,
        ),
      ),
    );
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
            currentNavKey: _currentNavKey,
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
                  else if (homeProvider.selectedTypeId != 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 28, top: 32, bottom: 8),
                      child: Text(
                        homeProvider.selectedTypeName,
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 24),

                  // Horizontal Section Rows (Top 10, Recommendations, etc.)
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
