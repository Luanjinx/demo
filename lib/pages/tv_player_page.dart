import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/detail_model.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import '../widgets/tv_focusable.dart';

enum TVAspectRatioMode {
  fit,
  sixteenNine,
  fill,
}

class TVPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String? subtitle;
  final List<EpisodeItem>? episodes;
  final int? currentEpisodeIndex;
  final List<QualityOption>? qualities;

  const TVPlayerPage({
    super.key,
    required this.videoUrl,
    required this.title,
    this.subtitle,
    this.episodes,
    this.currentEpisodeIndex,
    this.qualities,
  });

  @override
  State<TVPlayerPage> createState() => _TVPlayerPageState();
}

class _TVPlayerPageState extends State<TVPlayerPage> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _showControls = true;
  String? _errorMessage;
  Timer? _hideControlsTimer;

  // Seeking feedback overlay
  String? _seekFeedback;
  Timer? _seekFeedbackTimer;

  late String _currentVideoUrl;
  late String _currentTitle;
  int? _currentEpIndex;

  // ExoPlayer settings
  List<QualityOption> _availableQualities = [];
  String _selectedQualityLabel = "Auto";
  double _playbackSpeed = 1.0;
  TVAspectRatioMode _aspectRatioMode = TVAspectRatioMode.fit;
  bool _showSettingsMenu = false;
  bool _showEpisodeDrawer = false;

  bool get _hasNextEp =>
      widget.episodes != null &&
      _currentEpIndex != null &&
      _currentEpIndex! + 1 < widget.episodes!.length;

  @override
  void initState() {
    super.initState();
    _currentVideoUrl = widget.videoUrl;
    _currentTitle = widget.title;
    _currentEpIndex = widget.currentEpisodeIndex;

    // Initialize qualities list
    if (widget.qualities != null && widget.qualities!.isNotEmpty) {
      _availableQualities = List.from(widget.qualities!);
      _selectedQualityLabel = _availableQualities.first.label;
    } else if (widget.episodes != null &&
        _currentEpIndex != null &&
        _currentEpIndex! < widget.episodes!.length) {
      _availableQualities = widget.episodes![_currentEpIndex!].qualities;
      if (_availableQualities.isNotEmpty) {
        _selectedQualityLabel = _availableQualities.first.label;
      }
    }

    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initPlayer(_currentVideoUrl);
  }

  Future<void> _initPlayer(String url, {Duration? startPosition}) async {
    setState(() {
      _isInitialized = false;
      _errorMessage = null;
    });

    _controller?.removeListener(_playerListener);
    _controller?.dispose();
    _controller = null;

    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _errorMessage = "Tautan video belum tersedia.";
      });
      return;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      setState(() {
        _errorMessage = "Format tautan video tidak valid.";
      });
      return;
    }

    // Configure ExoPlayer controller with TV headers and options
    _controller = VideoPlayerController.networkUrl(
      uri,
      httpHeaders: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': Constant.baseUrl,
      },
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: false,
        allowBackgroundPlayback: false,
      ),
    );

    try {
      await _controller!.initialize();
      if (startPosition != null && startPosition > Duration.zero) {
        await _controller!.seekTo(startPosition);
      }
      await _controller!.setPlaybackSpeed(_playbackSpeed);
      await _controller!.play();
      _controller!.addListener(_playerListener);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null;
        });
        _startHideTimer();
      }
    } catch (e) {
      debugPrint("Error initializing ExoPlayer: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal memutar video dengan ExoPlayer. Server video sedang sibuk atau format tidak didukung.";
        });
      }
    }
  }

  void _playerListener() {
    if (!mounted) return;
    if (_controller != null && _controller!.value.hasError) {
      setState(() {
        _errorMessage = "Terjadi kesalahan saat pemutaran video ExoPlayer.";
      });
    }

    // Auto next episode on video completion
    if (_controller != null &&
        _controller!.value.isInitialized &&
        _controller!.value.duration > Duration.zero &&
        _controller!.value.position >= _controller!.value.duration) {
      if (_hasNextEp) {
        playNextEpisode();
      }
    }

    setState(() {});
  }

  void playNextEpisode() {
    if (_hasNextEp) {
      playEpisodeAtIndex(_currentEpIndex! + 1);
    }
  }

  void playEpisodeAtIndex(int index) {
    if (widget.episodes != null && index >= 0 && index < widget.episodes!.length) {
      final ep = widget.episodes![index];
      final epQualities = ep.qualities;
      final epUrl = ep.playableVideoUrl;

      if (epUrl.isNotEmpty) {
        setState(() {
          _currentEpIndex = index;
          _currentVideoUrl = epUrl;
          _currentTitle = ep.name ?? 'Episode ${index + 1}';
          _availableQualities = epQualities;
          if (_availableQualities.isNotEmpty) {
            _selectedQualityLabel = _availableQualities.first.label;
          }
          _showEpisodeDrawer = false;
        });
        _initPlayer(_currentVideoUrl);
      }
    }
  }

  Future<void> _changeQuality(QualityOption option) async {
    if (option.label == _selectedQualityLabel && option.url == _currentVideoUrl) return;

    final currentPosition = _controller?.value.position ?? Duration.zero;
    setState(() {
      _selectedQualityLabel = option.label;
      _currentVideoUrl = option.url;
      _showSettingsMenu = false;
    });

    await _initPlayer(option.url, startPosition: currentPosition);
  }

  Future<void> _setSpeed(double speed) async {
    setState(() {
      _playbackSpeed = speed;
      _showSettingsMenu = false;
    });
    if (_controller != null && _isInitialized) {
      await _controller!.setPlaybackSpeed(speed);
    }
  }

  void _toggleAspectRatio() {
    setState(() {
      if (_aspectRatioMode == TVAspectRatioMode.fit) {
        _aspectRatioMode = TVAspectRatioMode.sixteenNine;
      } else if (_aspectRatioMode == TVAspectRatioMode.sixteenNine) {
        _aspectRatioMode = TVAspectRatioMode.fill;
      } else {
        _aspectRatioMode = TVAspectRatioMode.fit;
      }
    });
  }

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted &&
          (_controller?.value.isPlaying ?? false) &&
          !_showSettingsMenu &&
          !_showEpisodeDrawer) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (!_showControls) {
        _showSettingsMenu = false;
        _showEpisodeDrawer = false;
      }
    });
    if (_showControls) {
      _startHideTimer();
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      setState(() {
        _showControls = true;
      });
      _hideControlsTimer?.cancel();
    } else {
      _controller!.play();
      _startHideTimer();
    }
  }

  void _seekBy(int seconds) {
    if (_controller == null || !_isInitialized) return;

    final current = _controller!.value.position;
    final target = current + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > _controller!.value.duration ? _controller!.value.duration : target);

    _controller!.seekTo(clamped);

    setState(() {
      _seekFeedback = seconds > 0 ? "+${seconds}s »" : "« ${seconds}s";
      _showControls = true;
    });
    _seekFeedbackTimer?.cancel();
    _seekFeedbackTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _seekFeedback = null;
        });
      }
    });

    _startHideTimer();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return hours > 0
        ? "$hours:${twoDigits(minutes)}:${twoDigits(seconds)}"
        : "${twoDigits(minutes)}:${twoDigits(seconds)}";
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _hideControlsTimer?.cancel();
    _seekFeedbackTimer?.cancel();
    _controller?.removeListener(_playerListener);
    _controller?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            final key = event.logicalKey;

            // Back key
            if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.goBack) {
              if (_showSettingsMenu || _showEpisodeDrawer) {
                setState(() {
                  _showSettingsMenu = false;
                  _showEpisodeDrawer = false;
                });
                return KeyEventResult.handled;
              }
              Navigator.pop(context);
              return KeyEventResult.handled;
            }

            // Enter / OK: Toggle Play / Pause if not selecting inside menu
            if (!_showSettingsMenu && !_showEpisodeDrawer) {
              if (key == LogicalKeyboardKey.select ||
                  key == LogicalKeyboardKey.enter ||
                  key == LogicalKeyboardKey.numpadEnter ||
                  key == LogicalKeyboardKey.gameButtonA) {
                _togglePlayPause();
                return KeyEventResult.handled;
              }

              // Left: Rewind 10s
              if (key == LogicalKeyboardKey.arrowLeft) {
                _seekBy(-10);
                return KeyEventResult.handled;
              }

              // Right: Fast Forward 10s
              if (key == LogicalKeyboardKey.arrowRight) {
                _seekBy(10);
                return KeyEventResult.handled;
              }

              // Up: Open Settings Menu
              if (key == LogicalKeyboardKey.arrowUp) {
                setState(() {
                  _showSettingsMenu = true;
                  _showControls = true;
                });
                return KeyEventResult.handled;
              }

              // Down: Toggle Controls
              if (key == LogicalKeyboardKey.arrowDown) {
                _toggleControls();
                return KeyEventResult.handled;
              }
            }
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Video Surface with ExoPlayer
              Center(
                child: _errorMessage != null
                    ? _buildErrorView()
                    : (_isInitialized && _controller != null)
                        ? _buildVideoSurface()
                        : const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: TVColors.primary),
                              SizedBox(height: 16),
                              Text("Memuat video dengan ExoPlayer...", style: TextStyle(color: Colors.white70)),
                            ],
                          ),
              ),

              // 2. Seek Visual Feedback Badge
              if (_seekFeedback != null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Text(
                      _seekFeedback!,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // 3. Overlay Controls
              if (_errorMessage == null)
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: Stack(
                      children: [
                        // Top Bar (Back, Title, ExoPlayer badge, Settings button)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.90),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Row(
                              children: [
                                TVFocusable(
                                  onPressed: () => Navigator.pop(context),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              _currentTitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.outfit(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          // ExoPlayer Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: TVColors.primary.withValues(alpha: 0.25),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: TVColors.primary, width: 0.8),
                                            ),
                                            child: Text(
                                              "ExoPlayer",
                                              style: GoogleFonts.outfit(
                                                color: TVColors.primary,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (widget.subtitle != null)
                                        Text(
                                          widget.subtitle!,
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            color: TVColors.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Aspect ratio toggle
                                TVFocusable(
                                  onPressed: _toggleAspectRatio,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _aspectRatioLabel,
                                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Settings button (Quality / Speed)
                                TVFocusable(
                                  onPressed: () {
                                    setState(() {
                                      _showSettingsMenu = !_showSettingsMenu;
                                      _showEpisodeDrawer = false;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _showSettingsMenu ? TVColors.primary : Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.settings_outlined, color: Colors.white, size: 16),
                                        const SizedBox(width: 6),
                                        Text(_selectedQualityLabel, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Episode drawer button
                                if (widget.episodes != null && widget.episodes!.length > 1) ...[
                                  TVFocusable(
                                    onPressed: () {
                                      setState(() {
                                        _showEpisodeDrawer = !_showEpisodeDrawer;
                                        _showSettingsMenu = false;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _showEpisodeDrawer ? TVColors.primary : Colors.white.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.video_library_outlined, color: Colors.white, size: 16),
                                          SizedBox(width: 6),
                                          Text("Episode", style: TextStyle(color: Colors.white, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],

                                // Next Ep button
                                if (_hasNextEp)
                                  TVFocusable(
                                    onPressed: playNextEpisode,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: TVColors.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text("Next Ep", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                          SizedBox(width: 4),
                                          Icon(Icons.skip_next_rounded, color: Colors.white, size: 18),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Center Play / Pause Indicator
                        if (_isInitialized && _controller != null && !_showSettingsMenu && !_showEpisodeDrawer)
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TVFocusable(
                                  onPressed: () => _seekBy(-10),
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.60),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 32),
                                  ),
                                ),
                                const SizedBox(width: 28),
                                TVFocusable(
                                  autoFocus: true,
                                  onPressed: _togglePlayPause,
                                  borderRadius: BorderRadius.circular(40),
                                  focusBorderColor: TVColors.primary,
                                  child: Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: TVColors.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: TVColors.primary.withValues(alpha: 0.5),
                                          blurRadius: 18,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _controller!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 42,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 28),
                                TVFocusable(
                                  onPressed: () => _seekBy(10),
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.60),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 32),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Bottom Bar (Progress, Time, Controls Hint)
                        if (_isInitialized && _controller != null && !_showSettingsMenu && !_showEpisodeDrawer)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 26),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.95),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  VideoProgressIndicator(
                                    _controller!,
                                    allowScrubbing: false,
                                    colors: const VideoProgressColors(
                                      playedColor: TVColors.primary,
                                      bufferedColor: Colors.white30,
                                      backgroundColor: Colors.white12,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Text(
                                        _formatDuration(_controller!.value.position),
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        " / ${_formatDuration(_controller!.value.duration)}",
                                        style: GoogleFonts.outfit(
                                          color: TVColors.textMuted,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const Spacer(),
                                      _remoteHint("OK", "Play/Pause"),
                                      const SizedBox(width: 16),
                                      _remoteHint("◄ ►", "±10s"),
                                      const SizedBox(width: 16),
                                      _remoteHint("▲", "Pengaturan"),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Settings Menu Overlay (Quality, Speed)
                        if (_showSettingsMenu) _buildSettingsOverlay(),

                        // Episode Drawer Overlay
                        if (_showEpisodeDrawer) _buildEpisodeDrawer(),
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

  Widget _buildVideoSurface() {
    switch (_aspectRatioMode) {
      case TVAspectRatioMode.sixteenNine:
        return AspectRatio(
          aspectRatio: 16 / 9,
          child: VideoPlayer(_controller!),
        );
      case TVAspectRatioMode.fill:
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          ),
        );
      case TVAspectRatioMode.fit:
        return AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        );
    }
  }

  String get _aspectRatioLabel {
    switch (_aspectRatioMode) {
      case TVAspectRatioMode.sixteenNine:
        return "16:9";
      case TVAspectRatioMode.fill:
        return "Fill";
      case TVAspectRatioMode.fit:
        return "Fit";
    }
  }

  Widget _buildSettingsOverlay() {
    return Positioned(
      top: 90,
      right: 32,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: TVColors.surfaceBg.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.tune_rounded, color: TVColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Pengaturan ExoPlayer",
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quality Options
            if (_availableQualities.isNotEmpty) ...[
              Text(
                "Resolusi / Kualitas Video",
                style: GoogleFonts.outfit(color: TVColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableQualities.map((q) {
                  final isSelected = q.label == _selectedQualityLabel;
                  return TVFocusable(
                    onPressed: () => _changeQuality(q),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? TVColors.primary : Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        q.label,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
            ],

            // Playback Speed Options
            Text(
              "Kecepatan Pemutaran",
              style: GoogleFonts.outfit(color: TVColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
                final isSelected = _playbackSpeed == speed;
                return TVFocusable(
                  onPressed: () => _setSpeed(speed),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? TVColors.primary : Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "${speed}x",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodeDrawer() {
    final eps = widget.episodes ?? [];
    return Positioned(
      top: 85,
      right: 0,
      bottom: 0,
      width: 380,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: TVColors.appBg.withValues(alpha: 0.97),
          border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.video_library_rounded, color: TVColors.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  "Pilih Episode",
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TVFocusable(
                  onPressed: () {
                    setState(() {
                      _showEpisodeDrawer = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: eps.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final ep = eps[index];
                  final isCurrent = index == _currentEpIndex;

                  return TVFocusable(
                    onPressed: () => playEpisodeAtIndex(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCurrent ? TVColors.primary.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCurrent ? TVColors.primary : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCurrent ? Icons.play_arrow_rounded : Icons.play_circle_outline_rounded,
                            color: isCurrent ? TVColors.primary : Colors.white70,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ep.name ?? "Episode ${index + 1}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: isCurrent ? Colors.white : Colors.white70,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline_rounded, color: TVColors.accent, size: 54),
        const SizedBox(height: 16),
        Text(
          _errorMessage!,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TVFocusable(
              autoFocus: true,
              onPressed: () => _initPlayer(_currentVideoUrl),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text("Kembali", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _remoteHint(String keyLabel, String action) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            keyLabel,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 6),
        Text(action, style: GoogleFonts.outfit(color: TVColors.textMuted, fontSize: 12)),
      ],
    );
  }
}
