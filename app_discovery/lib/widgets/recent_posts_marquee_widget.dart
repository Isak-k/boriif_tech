import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../core/theme/app_colors.dart';
import '../models/post_model.dart';
import '../core/routing/app_router.dart';
import 'cached_app_image.dart';

/// Horizontal widget displaying recent posts that moves horizontally in a
/// continuous, seamless, infinite scrolling animation (marquee style).
/// Movement runs continuously at native display refresh rate without visible jumps or blank space.
/// Pauses when user touches/interacts and resumes automatically.
class RecentPostsMarqueeWidget extends StatefulWidget {
  final List<Post> posts;

  const RecentPostsMarqueeWidget({
    super.key,
    required this.posts,
  });

  @override
  State<RecentPostsMarqueeWidget> createState() => _RecentPostsMarqueeWidgetState();
}

class _RecentPostsMarqueeWidgetState extends State<RecentPostsMarqueeWidget>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final Ticker _ticker;

  Duration _lastDuration = Duration.zero;
  bool _isUserInteracting = false;
  Timer? _resumeTimer;

  static const double _cardWidth = 220.0;
  static const double _cardMarginHorizontal = 6.0; // 6px on each side = 12px between cards
  static const double _itemExtent = _cardWidth + (_cardMarginHorizontal * 2); // 232.0 px
  static const double _scrollSpeedPixelsPerSecond = 34.0; // smooth consistent speed

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      if (_lastDuration == Duration.zero) {
        _lastDuration = elapsed;
        return;
      }

      final deltaSeconds = (elapsed - _lastDuration).inMicroseconds / 1000000.0;
      _lastDuration = elapsed;

      // Do not auto-scroll if user is touching/interacting or posts are too few
      if (_isUserInteracting || widget.posts.isEmpty) return;
      if (!_scrollController.hasClients || !_scrollController.position.hasContentDimensions) return;

      final recentCount = widget.posts.take(10).length;
      if (recentCount == 0) return;

      final singleLoopWidth = recentCount * _itemExtent;
      final currentOffset = _scrollController.offset;
      var nextOffset = currentOffset + (_scrollSpeedPixelsPerSecond * deltaSeconds);

      // Seamless infinite wrapping: when offset exceeds one full cycle,
      // subtract singleLoopWidth. Since items repeat identically, this transition is 100% invisible.
      if (nextOffset >= singleLoopWidth && singleLoopWidth > 0) {
        nextOffset -= singleLoopWidth;
      }

      _scrollController.jumpTo(nextOffset);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.posts.isNotEmpty) {
        _ticker.start();
      }
    });
  }

  @override
  void didUpdateWidget(covariant RecentPostsMarqueeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.posts.isNotEmpty && !_ticker.isActive) {
      _ticker.start();
    } else if (widget.posts.isEmpty && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _resumeTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onUserInteractionStart() {
    _resumeTimer?.cancel();
    if (!_isUserInteracting) {
      setState(() {
        _isUserInteracting = true;
      });
    }
  }

  void _onUserInteractionEnd() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        // Normalize offset within the seamless loop window before resuming
        if (_scrollController.hasClients && _scrollController.position.hasContentDimensions) {
          final recentCount = widget.posts.take(10).length;
          final singleLoopWidth = recentCount * _itemExtent;
          if (singleLoopWidth > 0 && _scrollController.offset >= singleLoopWidth) {
            _scrollController.jumpTo(_scrollController.offset % singleLoopWidth);
          }
        }
        setState(() {
          _isUserInteracting = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.posts.isEmpty) {
      return const SizedBox.shrink();
    }

    final recentPosts = widget.posts.take(10).toList();
    // Replicate list 8 times to provide an infinite continuous buffer
    final displayList = recentPosts.length > 1
        ? [
            ...recentPosts,
            ...recentPosts,
            ...recentPosts,
            ...recentPosts,
            ...recentPosts,
            ...recentPosts,
            ...recentPosts,
            ...recentPosts,
          ]
        : recentPosts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.cyan,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan,
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Recent Posts',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Text(
                'Continuous Feed',
                style: TextStyle(
                  color: AppColors.cyan.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Continuous horizontal marquee with pause on interaction
        SizedBox(
          height: 182,
          child: Listener(
            onPointerDown: (_) => _onUserInteractionStart(),
            onPointerUp: (_) => _onUserInteractionEnd(),
            onPointerCancel: (_) => _onUserInteractionEnd(),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification) {
                  _onUserInteractionStart();
                } else if (notification is ScrollEndNotification) {
                  _onUserInteractionEnd();
                }
                return false;
              },
              child: ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(
                  scrollbars: false,
                  overscroll: false,
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final post = displayList[index];
                    return _buildRecentCard(context, post);
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildRecentCard(BuildContext context, Post post) {
    return Container(
      width: _cardWidth,
      margin: const EdgeInsets.symmetric(
        horizontal: _cardMarginHorizontal,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF101622),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Pass the entire Post object directly for 0ms instantaneous opening
            Navigator.pushNamed(
              context,
              AppRouter.postDetails,
              arguments: post,
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image container with overlays
              Stack(
                children: [
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                    ),
                    child: CachedAppImage(
                      imageUrl: post.imageUrl,
                      width: double.infinity,
                      height: 100,
                      fit: BoxFit.cover,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                      placeholderIcon: Icons.image_outlined,
                    ),
                  ),

                  // Post Code Badge (Top-left)
                  if (post.code.isNotEmpty)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xDD000000),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.cyan,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '#${post.code}',
                          style: const TextStyle(
                            color: AppColors.cyan,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Title and metrics
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        post.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.visibility_outlined,
                                size: 13,
                                color: AppColors.cyan,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post.viewsCount}',
                                style: const TextStyle(
                                  color: AppColors.cyan,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.favorite,
                                size: 13,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post.likesCount}',
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
    );
  }
}
