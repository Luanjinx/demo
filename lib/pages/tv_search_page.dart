import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/tv_home_provider.dart';
import '../utils/color.dart';
import '../widgets/tv_card.dart';
import '../widgets/tv_focusable.dart';
import 'tv_details_page.dart';

class TVSearchPage extends StatefulWidget {
  const TVSearchPage({super.key});

  @override
  State<TVSearchPage> createState() => _TVSearchPageState();
}

class _TVSearchPageState extends State<TVSearchPage> {
  final TextEditingController _queryController = TextEditingController();

  final List<String> _keyboardKeys = [
    'A', 'B', 'C', 'D', 'E', 'F',
    'G', 'H', 'I', 'J', 'K', 'L',
    'M', 'N', 'O', 'P', 'Q', 'R',
    'S', 'T', 'U', 'V', 'W', 'X',
    'Y', 'Z', '1', '2', '3', '4',
    '5', '6', '7', '8', '9', '0',
    'SPASI', 'HAPUS', 'BERSIHKAN',
  ];

  void _onKeyPress(String key) {
    final homeProvider = Provider.of<TVHomeProvider>(context, listen: false);

    if (key == 'HAPUS') {
      if (_queryController.text.isNotEmpty) {
        _queryController.text =
            _queryController.text.substring(0, _queryController.text.length - 1);
      }
    } else if (key == 'BERSIHKAN') {
      _queryController.clear();
    } else if (key == 'SPASI') {
      _queryController.text += ' ';
    } else {
      _queryController.text += key;
    }

    homeProvider.search(_queryController.text);
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<TVHomeProvider>(context);

    return Scaffold(
      backgroundColor: TVColors.appBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar (Back button and Search Query display)
              Row(
                children: [
                  TVFocusable(
                    onPressed: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: TVColors.surfaceBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: TVColors.textMuted, size: 22),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              _queryController.text.isEmpty
                                  ? "Gunakan remote untuk mengetik judul film, drama, atau anime..."
                                  : _queryController.text,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: _queryController.text.isEmpty
                                    ? TVColors.textMuted
                                    : Colors.white,
                                fontWeight: _queryController.text.isEmpty
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_queryController.text.isNotEmpty)
                            Text(
                              "${homeProvider.searchResults.length} Hasil",
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: TVColors.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Body: Left Keyboard Grid & Right Results Grid
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TV Keyboard (Left)
                    SizedBox(
                      width: 320,
                      child: GridView.builder(
                        itemCount: _keyboardKeys.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          childAspectRatio: 1.1,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemBuilder: (context, index) {
                          final key = _keyboardKeys[index];
                          final bool isAction = key == 'SPASI' || key == 'HAPUS' || key == 'BERSIHKAN';

                          return TVFocusable(
                            onPressed: () => _onKeyPress(key),
                            scaleFactor: 1.12,
                            borderRadius: BorderRadius.circular(6),
                            focusBorderColor: TVColors.focusBorder,
                            focusGlowColor: TVColors.focusPrimaryGlow,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isAction
                                    ? TVColors.primary.withValues(alpha: 0.35)
                                    : TVColors.surfaceBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                  width: 0.8,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                key,
                                style: GoogleFonts.outfit(
                                  fontSize: isAction ? 9 : 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 30),

                    // Search Results Grid (Right)
                    Expanded(
                      child: homeProvider.isSearching
                          ? const Center(child: CircularProgressIndicator(color: TVColors.primary))
                          : homeProvider.searchResults.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.movie_filter_outlined,
                                        color: TVColors.textMuted,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _queryController.text.isEmpty
                                            ? "Ketik untuk mencari judul favorit Anda"
                                            : "Tidak ada judul yang cocok dengan pencarian",
                                        style: GoogleFonts.outfit(
                                          color: TVColors.textMuted,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  clipBehavior: Clip.none,
                                  itemCount: homeProvider.searchResults.length,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    childAspectRatio: 0.65,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = homeProvider.searchResults[index];
                                    return TVCard(
                                      item: item,
                                      layout: TVCardLayout.portrait,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => TVDetailsPage(
                                              id: item.id ?? 0,
                                              videoType: item.videoType ?? 1,
                                              typeId: item.typeId ?? 0,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
