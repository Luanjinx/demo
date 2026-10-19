import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/tv_auth_provider.dart';
import '../providers/tv_home_provider.dart';
import '../utils/color.dart';
import 'tv_focusable.dart';

class TVSidebar extends StatefulWidget {
  final String currentNavKey;
  final Function(String navKey, {int? typeId, String? typeName}) onSelect;

  const TVSidebar({
    super.key,
    required this.currentNavKey,
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

  IconData _getIconForType(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('movie') || lower.contains('film')) {
      return Icons.movie_outlined;
    } else if (lower.contains('drama') || lower.contains('show') || lower.contains('series') || lower.contains('serial')) {
      return Icons.tv_rounded;
    } else if (lower.contains('anime')) {
      return Icons.auto_awesome_rounded;
    } else if (lower.contains('short') || lower.contains('klip') || lower.contains('clip')) {
      return Icons.play_circle_outline_rounded;
    } else if (lower.contains('kid') || lower.contains('anak')) {
      return Icons.child_care_rounded;
    } else if (lower.contains('live')) {
      return Icons.live_tv_rounded;
    } else if (lower.contains('music') || lower.contains('musik')) {
      return Icons.music_note_rounded;
    } else if (lower.contains('sport') || lower.contains('olahraga')) {
      return Icons.sports_soccer_rounded;
    }
    return Icons.grid_view_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<TVAuthProvider>(context);
    final homeProvider = Provider.of<TVHomeProvider>(context);
    final double width = _isExpanded ? 210.0 : 68.0;

    return MouseRegion(
      onEnter: (_) => _setExpanded(true),
      onExit: (_) => _setExpanded(false),
      child: FocusScope(
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
                padding: _isExpanded
                    ? const EdgeInsets.symmetric(horizontal: 14.0)
                    : EdgeInsets.zero,
                child: Row(
                  mainAxisAlignment: _isExpanded
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: TVColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: TVColors.primary.withValues(alpha: 0.40),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
              const SizedBox(height: 16),

              // Navigation Items
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // 1. Search
                      _buildNavItem(
                        navKey: 'search',
                        icon: Icons.search_rounded,
                        label: "Pencarian",
                        onTap: () => widget.onSelect('search'),
                      ),

                      // 2. Beranda (Home)
                      _buildNavItem(
                        navKey: 'home',
                        icon: Icons.home_rounded,
                        label: "Beranda",
                        onTap: () => widget.onSelect('home', typeId: 0, typeName: "Beranda"),
                      ),

                      // 3. Dynamic Types / Sections from API (Movies, Drama, Anime, Shorts, Kids, LiveTV)
                      ...homeProvider.types.map((type) {
                        final key = 'type_${type.id}';
                        return _buildNavItem(
                          navKey: key,
                          icon: _getIconForType(type.name ?? ''),
                          label: type.name ?? '',
                          onTap: () => widget.onSelect(
                            key,
                            typeId: type.id ?? 0,
                            typeName: type.name ?? '',
                          ),
                        );
                      }),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.08),
                          height: 1,
                        ),
                      ),

                      // 4. Aktivasi TV / Profile
                      _buildNavItem(
                        navKey: 'login',
                        icon: auth.isLoggedIn ? Icons.account_circle_rounded : Icons.login_rounded,
                        label: auth.isLoggedIn ? (auth.currentUser?.name ?? "Profil") : "Aktivasi TV",
                        isSpecial: !auth.isLoggedIn,
                        onTap: () => widget.onSelect('login'),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String navKey,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSpecial = false,
  }) {
    final bool isSelected = widget.currentNavKey == navKey;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      child: TVFocusable(
        scaleFactor: 1.05,
        borderRadius: BorderRadius.circular(10),
        focusBorderColor: isSpecial ? TVColors.accent : TVColors.focusBorder,
        focusGlowColor: isSpecial ? TVColors.accent.withValues(alpha: 0.4) : TVColors.focusGlow,
        onPressed: onTap,
        child: Container(
          height: 42,
          padding: _isExpanded
              ? const EdgeInsets.symmetric(horizontal: 12)
              : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: isSelected ? TVColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: TVColors.primary.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: _isExpanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : isSpecial
                        ? TVColors.accent
                        : TVColors.textSecondary,
                size: 22,
              ),
              if (_isExpanded) ...[
                const SizedBox(width: 12),
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
                              : TVColors.textPrimary,
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
