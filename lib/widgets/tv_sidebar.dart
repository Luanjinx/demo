import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/tv_auth_provider.dart';
import '../utils/color.dart';
import 'tv_focusable.dart';

enum TVNavDestination {
  search,
  home,
  movies,
  series,
  anime,
  login,
}

class TVSidebar extends StatefulWidget {
  final TVNavDestination currentNav;
  final Function(TVNavDestination destination) onSelect;

  const TVSidebar({
    super.key,
    required this.currentNav,
    required this.onSelect,
  });

  @override
  State<TVSidebar> createState() => _TVSidebarState();
}

class _TVSidebarState extends State<TVSidebar> {
  bool _isExpanded = false;

  void _setExpanded(bool expanded) {
    if (_isExpanded != expanded) {
      setState(() {
        _isExpanded = expanded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<TVAuthProvider>(context);
    final double width = _isExpanded ? 210.0 : 68.0;

    return FocusScope(
      onFocusChange: (hasFocus) {
        _setExpanded(hasFocus);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: width,
        height: double.infinity,
        decoration: BoxDecoration(
          color: TVColors.sidebarBg.withValues(alpha: 0.96),
          border: Border(
            right: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          boxShadow: _isExpanded
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.60),
                    blurRadius: 24,
                    offset: const Offset(4, 0),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Logo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: TVColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "NEXSTREAM",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Navigation Items
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildNavItem(
                      destination: TVNavDestination.search,
                      icon: Icons.search_rounded,
                      label: "Pencarian",
                    ),
                    _buildNavItem(
                      destination: TVNavDestination.home,
                      icon: Icons.home_rounded,
                      label: "Beranda",
                    ),
                    _buildNavItem(
                      destination: TVNavDestination.movies,
                      icon: Icons.movie_outlined,
                      label: "Film",
                    ),
                    _buildNavItem(
                      destination: TVNavDestination.series,
                      icon: Icons.tv_rounded,
                      label: "Serial / Drama",
                    ),
                    _buildNavItem(
                      destination: TVNavDestination.anime,
                      icon: Icons.auto_awesome_rounded,
                      label: "Anime",
                    ),
                    const SizedBox(height: 10),
                    _buildNavItem(
                      destination: TVNavDestination.login,
                      icon: auth.isLoggedIn ? Icons.account_circle_rounded : Icons.login_rounded,
                      label: auth.isLoggedIn ? (auth.currentUser?.name ?? "Profil") : "Aktivasi TV",
                      isSpecial: !auth.isLoggedIn,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required TVNavDestination destination,
    required IconData icon,
    required String label,
    bool isSpecial = false,
  }) {
    final bool isSelected = widget.currentNav == destination;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
      child: TVFocusable(
        scaleFactor: 1.04,
        borderRadius: BorderRadius.circular(8),
        focusBorderColor: isSpecial ? TVColors.accent : TVColors.focusBorder,
        focusGlowColor: isSpecial ? TVColors.accent.withValues(alpha: 0.4) : TVColors.focusGlow,
        onPressed: () {
          widget.onSelect(destination);
        },
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? TVColors.primary.withValues(alpha: 0.20)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: TVColors.primary.withValues(alpha: 0.50), width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? TVColors.primary
                    : isSpecial
                        ? TVColors.accent
                        : TVColors.textSecondary,
                size: 22,
              ),
              if (_isExpanded) ...[
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : isSpecial
                              ? TVColors.accent
                              : TVColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
