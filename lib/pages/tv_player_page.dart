import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/detail_model.dart';
import '../utils/color.dart';
import '../widgets/tv_focusable.dart';

class TVPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String? subtitle;
  final List<EpisodeItem>? episodes;
  final int? currentEpisodeIndex;

  const TVPlayerPage({
    super.key,
    required this.videoUrl,
    required this.title,
    this.subtitle,
    this.episodes,
    this.currentEpisodeIndex,
  });

  @override
  State<TVPlayerPage> createState() => _TVPlayerPageState();
}

class _TVPlayerPageState extends State<TVPlayerPage> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  // Seeking feedback overlay
  String? _seekFeedback;
  Timer? _seekFeedbackTimer;

  late String _currentVideoUrl;
  late String _currentTitle;
  int? _currentEpIndex;

  void playNextEpisode() {
    if (widget.episodes != null &&
        _currentEpIndex != null &&
        _currentEpIndex! + 1 < widget.episodes!.length) {
      setState(() {
        _currentEpIndex = _currentEpIndex! + 1;
        final nextEp = widget.episodes![_currentEpIndex!];
        _currentVideoUrl = nextEp.videoUrl ?? '';
        _currentTitle = nextEp.name ?? 'Episode ${_currentEpIndex! + 1}';
      });
      _initPlayer(_currentVideoUrl);
    }
  }

  @override
  void initState() {
    super.initState();
    _currentVideoUrl = widget.videoUrl;
    _currentTitle = widget.title;
    _currentEpIndex = widget.currentEpisodeIndex;

    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initPlayer(_currentVideoUrl);
  }

  Future<void> _initPlayer(String url) async {
    setState(() {
      _isInitialized = false;
    });

    _controller?.dispose();

    if (url.isEmpty) return;

    _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await _controller!.initialize();
      _controller!.play();
      _controller!.addListener(_playerListener);
      setState(() {
        _isInitialized = true;
      });
      _startHideTimer();
    } catch (e) {
      debugPrint("Error initializing player: $e");
    }
  }

  void _playerListener() {
    if (mounted) setState(() {});
  }

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
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

    // Show visual seek feedback
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

            // Center OK / Enter: Toggle Play / Pause
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

            // Up / Down: Toggle Overlay Controls
            if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowDown) {
              _toggleControls();
              return KeyEventResult.handled;
            }

            // Back
            if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.goBack) {
              Navigator.pop(context);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video Surface
              Center(
                child: _isInitialized && _controller != null
                    ? AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      )
                    : const CircularProgressIndicator(color: TVColors.primary),
              ),

              // Seek Visual Feedback Badge
              if (_seekFeedback != null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.80),
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

              // Overlay Controls
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Stack(
                    children: [
                      // Top Bar (Back button, Title)
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
                                Colors.black.withValues(alpha: 0.85),
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
                                    Text(
                                      _currentTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
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
                            ],
                          ),
                        ),
                      ),

                      // Bottom Bar (Progress slider, times, D-pad hints)
                      if (_isInitialized && _controller != null)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
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
                                // Progress Bar
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

                                // Time and Status
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}",
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),

                                    // Remote D-pad Controls Legend
                                    Row(
                                      children: [
                                        _legendPill("◄ ►", "Seek ±10s"),
                                        const SizedBox(width: 12),
                                        _legendPill("OK", _controller!.value.isPlaying ? "Pause" : "Play"),
                                        const SizedBox(width: 12),
                                        _legendPill("▲ ▼", "Menu"),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
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

  Widget _legendPill(String keyLabel, String actionLabel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            keyLabel,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: TVColors.accent,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            actionLabel,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
