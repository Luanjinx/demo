import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/section_model.dart';
import '../utils/color.dart';
import 'tv_card.dart';

class TVSectionRow extends StatelessWidget {
  final SectionItem section;
  final Function(ContentItem item, SectionItem section) onContentTap;

  const TVSectionRow({
    super.key,
    required this.section,
    required this.onContentTap,
  });

  TVCardLayout _resolveLayout() {
    final layout = (section.screenLayout ?? 'portrait').toLowerCase();
    switch (layout) {
      case 'landscape':
      case 'big_landscape':
        return TVCardLayout.landscape;
      case 'index_landscape':
        return TVCardLayout.indexLandscape;
      case 'index_portrait':
        return TVCardLayout.indexPortrait;
      case 'square':
        return TVCardLayout.square;
      case 'portrait':
      case 'big_portrait':
      default:
        return TVCardLayout.portrait;
    }
  }

  double _rowHeight(TVCardLayout layout) {
    switch (layout) {
      case TVCardLayout.portrait:
      case TVCardLayout.indexPortrait:
        return 235.0;
      case TVCardLayout.landscape:
      case TVCardLayout.indexLandscape:
        return 165.0;
      case TVCardLayout.square:
        return 185.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = section.data ?? [];
    if (items.isEmpty) return const SizedBox.shrink();

    final layout = _resolveLayout();
    final double height = _rowHeight(layout);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
            child: Row(
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
                  section.title ?? '',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: TVColors.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // Horizontal List
          SizedBox(
            height: height,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isIndexed = layout == TVCardLayout.indexPortrait ||
                    layout == TVCardLayout.indexLandscape;

                return TVCard(
                  item: item,
                  layout: layout,
                  indexRank: isIndexed ? index : null,
                  onTap: () => onContentTap(item, section),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
