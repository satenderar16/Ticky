// import 'dart:async';
// import 'dart:math';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
// // import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
// import 'package:quthon/Widgets/animated_loading.dart';

// class PinterestLikeFeed extends StatefulWidget {
//   const PinterestLikeFeed({super.key});

//   @override
//   State<PinterestLikeFeed> createState() => _PinterestLikeFeedState();
// }

// class _PinterestLikeFeedState extends State<PinterestLikeFeed> {
//   final ScrollController _scrollController = ScrollController();
//   final List<String> _images = [];
//   bool _isLoading = false;
//   int _page = 1;
//   final int _limit = 40;
//   bool _hasMore = true;

//   // Track the last tapped URL
//   String? _lastTappedUrl;
//   @override
//   void initState() {
//     super.initState();
//     _fetchMore();
//     _scrollController.addListener(_onScroll);
//   }

//   void _updateLastTapped(String url) {
//     setState(() {
//       _lastTappedUrl = url;
//     });
//   }

//   void _onScroll() {
//     if (_scrollController.position.pixels >=
//             _scrollController.position.maxScrollExtent - 300 &&
//         !_isLoading &&
//         _hasMore) {
//       _fetchMore();
//     }
//   }

//   Future<void> _fetchMore() async {
//     if (_isLoading || !_hasMore) return;
//     setState(() => _isLoading = true);

//     final newUrls = await fetchImages(_page, _limit);
//     await Future.wait(
//       newUrls.map((url) => _precacheImage(url)),
//     ); // to first cached them then how them

//     setState(() {
//       _images.addAll(newUrls);
//       _isLoading = false;
//       _page++;
//       if (newUrls.length < _limit) _hasMore = false;
//     });
//   }

//   Future<void> _precacheImage(String url) async {
//     final image = CachedNetworkImageProvider(url);
//     await precacheImage(image, context);
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scrollbar(
//       controller: _scrollController,
//       child: CustomScrollView(
//         controller: _scrollController,
//         slivers: [
//           SliverPadding(
//             padding: const EdgeInsets.all(8),
//             sliver: SliverMasonryGrid(
//               gridDelegate: SliverSimpleGridDelegateWithMaxCrossAxisExtent(
//                 maxCrossAxisExtent: 150,
//               ),
//               crossAxisSpacing: 10,
//               mainAxisSpacing: 10,
//               delegate: SliverChildBuilderDelegate(
//                 (context, index) => MasonryImageItem(
//                   url: _images[index],
//                   lastTappedUrl: _lastTappedUrl, // pass down
//                   onTap: _updateLastTapped, // callback to update
//                 ),
//                 childCount: _images.length,
//               ),
//             ),
//           ),
//           if (_isLoading)
//             const SliverToBoxAdapter(
//               child: Padding(
//                 padding: EdgeInsets.all(16),
//                 child: Center(child: CircularProgressIndicator()),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// /// Simulated network image fetcher
// Future<List<String>> fetchImages(int page, int limit) async {
//   await Future.delayed(const Duration(seconds: 1));
//   final random = Random();
//   return List.generate(limit, (i) {
//     final height = 200 + random.nextInt(300); // random heights 200–500
//     return 'https://picsum.photos/id/${page * limit + i}/300/$height';
//   });
// }

// class MasonryImageItem extends StatefulWidget {
//   final String url;
//   final String? lastTappedUrl;
//   final ValueChanged<String> onTap; // callback to notify parent

//   const MasonryImageItem({
//     required this.url,
//     required this.lastTappedUrl,
//     required this.onTap,
//     super.key,
//   });

//   @override
//   State<MasonryImageItem> createState() => _MasonryImageItemState();
// }

// class _MasonryImageItemState extends State<MasonryImageItem>
//     with AutomaticKeepAliveClientMixin {
//   @override
//   bool get wantKeepAlive => true;

//   bool _hasThumbnailError = false;
//   bool _hasHighResError = false;
//   bool _isLoadingHighRes = false;

//   @override
//   Widget build(BuildContext context) {
//     super.build(context);

//     final isLoadingThisCard =
//         _isLoadingHighRes && widget.lastTappedUrl == widget.url;

//     // Disable tap if high-res is loading or errored
//     final canTap =
//         !_hasHighResError && !_isLoadingHighRes && !_hasThumbnailError;

//     return GestureDetector(
//       onTap:
//           canTap
//               ? () async {
//                 // Notify parent this card was tapped
//                 widget.onTap(widget.url);

//                 setState(() {
//                   _isLoadingHighRes = true;
//                   _hasHighResError = false;
//                 });

//                 try {
//                   final (highResUrl, image) = await fetchHighResImage(
//                     widget.url,
//                   );

//                   if (!mounted) return;

//                   if (widget.lastTappedUrl == widget.url) {
//                     await precacheImage(
//                       CachedNetworkImageProvider(highResUrl),
//                       context,
//                     );

//                     final imageWidget = Hero(
//                       tag: widget.url,
//                       child: Image(
//                         image: CachedNetworkImageProvider(highResUrl),
//                         fit: BoxFit.contain,
//                       ),
//                     );

//                     if (!mounted) return;

//                     setState(() {
//                       _isLoadingHighRes = false;
//                     });
//                     if(!context.mounted)return;
//                     Navigator.of(context).push(
//                       PageRouteBuilder(
//                         opaque: false,
//                         pageBuilder:
//                             (_, __, ___) => FullscreenImageViewer(
//                               imageUrl: widget.url,
//                               highResImage: imageWidget,
//                             ),
//                         transitionsBuilder:
//                             (_, anim, __, child) =>
//                                 FadeTransition(opacity: anim, child: child),
//                       ),
//                     );
//                   } else {
//                     setState(() {
//                       _isLoadingHighRes = false;
//                     });
//                   }
//                 } catch (_) {
//                   if (!mounted) return;
//                   setState(() {
//                     _isLoadingHighRes = false;
//                     _hasHighResError = true;
//                   });
//                 }
//               }
//               : null,
//       child: Stack(
//         children: [
//           // Thumbnail image / card
//           Hero(
//             tag: widget.url,
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(12),
//               child: CachedNetworkImage(
//                 imageUrl: widget.url,
//                 fit: BoxFit.cover,
//                 errorWidget: (context, url, error) {
//                   WidgetsBinding.instance.addPostFrameCallback((_) {
//                     if (mounted && !_hasThumbnailError) {
//                       setState(() {
//                         _hasThumbnailError = true;
//                       });
//                     }
//                   });
//                   return SizedBox(
//                     height: 200,
//                     child: Card(
//                       elevation: 0,
//                       color: Theme.of(context).colorScheme.surfaceContainer,
//                       child: Center(
//                         child: Icon(
//                           Icons.broken_image,
//                           color:
//                               Theme.of(
//                                 context,
//                               ).colorScheme.surfaceContainerHighest,
//                           size: 40,
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),

//           // Loading overlay for high-res
//           if (isLoadingThisCard)
//             Positioned.fill(
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.black45,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Center(child: ThreeDotWave(color: Colors.white)),
//               ),
//             ),

//           // Error overlay for high-res fetch
//           if (_hasHighResError)
//             Positioned.fill(
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.black45,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Center(
//                   child: IconButton(
//                     icon: const Icon(
//                       Icons.refresh,
//                       size: 40,
//                       color: Colors.white,
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _hasHighResError = false;
//                         _isLoadingHighRes = true;
//                       });
//                       widget.onTap(widget.url);
//                     },
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Future<(String url, ImageProvider imageProvider)> fetchHighResImage(
//     String url,
//   ) async {
//     await Future.delayed(const Duration(seconds: 1));

//     final parts = url.split('/');
//     final id = parts[parts.length - 3];
//     final highResUrl = 'https://picsum.photos/id/$id/4000/3000';

//     final imageProvider = CachedNetworkImageProvider(highResUrl);

//     return (highResUrl, imageProvider);
//   }
// }

// class FullscreenImageViewer extends StatefulWidget {
//   final String imageUrl; // already loaded high-res image
//   final Widget highResImage; // already loaded/cached
//   const FullscreenImageViewer({
//     required this.imageUrl,
//     required this.highResImage,
//     super.key,
//   });

//   @override
//   State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
// }

// class _FullscreenImageViewerState extends State<FullscreenImageViewer>
//     with SingleTickerProviderStateMixin {
//   double _scale = 1.0;
//   double _previousScale = 1.0;
//   Offset _position = Offset.zero;
//   Offset _startPosition = Offset.zero;
//   double _dragOffset = 0.0;

//   late AnimationController _doubleTapController;
//   late Animation<double> _doubleTapAnimation;
//   Offset? _doubleTapFocalPoint;
//   Offset _startDoubleTapPosition = Offset.zero;

//   @override
//   void initState() {
//     super.initState();
//     _doubleTapController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//   }

//   @override
//   void dispose() {
//     _doubleTapController.dispose();
//     super.dispose();
//   }

//   void _handleDoubleTap(Offset tapPosition) {
//     final targetScale = _scale > 1.0 ? 1.0 : 2.5;
//     _startDoubleTapPosition = _position;
//     _doubleTapFocalPoint = tapPosition;

//     _doubleTapAnimation = Tween<double>(
//       begin: _scale,
//       end: targetScale,
//     ).animate(
//       CurvedAnimation(parent: _doubleTapController, curve: Curves.easeInOut),
//     )..addListener(() {
//       setState(() {
//         _scale = _doubleTapAnimation.value;

//         // Animate position back to center if zooming out
//         if (_scale <= 1.0) {
//           _position =
//               Offset.lerp(
//                 _startDoubleTapPosition,
//                 Offset.zero,
//                 1.0 - _scale / targetScale,
//               )!;
//         }
//       });
//     });

//     _doubleTapController.forward(from: 0.0);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onDoubleTapDown: (details) => _handleDoubleTap(details.localPosition),
//       onScaleStart: (details) {
//         _previousScale = _scale;
//         _startPosition = _position;
//       },
//       onScaleUpdate: (details) {
//         if (details.pointerCount == 1) {
//           if (_scale <= 1.0) {
//             // drag-to-dismiss when not zoomed
//             setState(() {
//               _dragOffset += details.focalPointDelta.dy;
//             });
//           } else {
//             // Bounded pan when zoomed
//             final screenSize = MediaQuery.of(context).size;
//             final imageWidth = screenSize.width * _scale;
//             final imageHeight = screenSize.height * _scale;

//             // Max pan in X and Y directions
//             final maxX = (imageWidth - screenSize.width) / 4;
//             final maxY = (imageHeight - screenSize.height) / 4;

//             // New tentative position
//             double newX = _position.dx + details.focalPointDelta.dx;
//             double newY = _position.dy + details.focalPointDelta.dy;

//             // Clamp position so image edges don’t go past screen
//             newX = newX.clamp(-maxX, maxX);
//             newY = newY.clamp(-maxY, maxY);

//             setState(() {
//               _position = Offset(newX, newY);
//             });
//           }
//         } else if (details.pointerCount == 2) {
//           // Pinch-to-zoom
//           double newScale = (_previousScale * details.scale).clamp(1.0, 4.0);

//           final screenSize = MediaQuery.of(context).size;
//           final imageWidth = screenSize.width * newScale;
//           final imageHeight = screenSize.height * newScale;
//           final maxX = (imageWidth - screenSize.width) / 2;
//           final maxY = (imageHeight - screenSize.height) / 2;

//           // Optional: adjust position to stay within bounds after zoom
//           double newX = _position.dx.clamp(-maxX, maxX);
//           double newY = _position.dy.clamp(-maxY, maxY);

//           setState(() {
//             _scale = newScale;
//             _position = Offset(newX, newY);
//           });
//         }
//       },
//       onScaleEnd: (details) {
//         if (_scale <= 1.0 && _dragOffset > 200) {
//           Navigator.of(context).pop();
//         } else {
//           setState(() {
//             _dragOffset = 0.0;
//           });
//         }
//         _previousScale = _scale;
//       },
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           // Background opacity
//           Positioned.fill(
//             child: Opacity(
//               opacity: (1.0 - (_dragOffset.abs() / 400)).clamp(0.0, 1.0),
//               child: Container(color: Colors.black87),
//             ),
//           ),
//           // Hero + image with transform
//           Positioned.fill(
//             child: Transform(
//               alignment: Alignment.center,
//               transform: Matrix4.translationValues(
//                 _position.dx,
//                 _position.dy + _dragOffset,
//                 0,
//               )..multiply(Matrix4.diagonal3Values(_scale, _scale, 1.0)),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.zero,
//                 child: widget.highResImage,
//               ),
//             ),
//           ),
//           // Fixed close button top-center
//           Positioned(
//             top: MediaQuery.of(context).padding.top + 16,
//             right: 16, // distance from the right edge
//             child: Material(
//               color: Colors.black45,
//               shape: const CircleBorder(),
//               child: IconButton(
//                 icon: const Icon(Icons.close, color: Colors.white),
//                 onPressed: () => Navigator.of(context).pop(),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
