// import 'package:flutter/material.dart';
// import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

// typedef FetchFunction<T> = Future<(List<T>, int)> Function(int offset);
// typedef ItemBuilder<T> =
//     Widget Function(BuildContext context, T item, int index);

// class InfiniteMasonryGrid<T> extends StatefulWidget {
//   final FetchFunction<T> fetchItems;
//   final ItemBuilder<T> itemBuilder;
//   final bool initialFetch;
//   final double scrollThreshold;
//   // final int limit;
//   final double crossAxisMax;
//   final double mainAxisSpacing;
//   final double crossAxisSpacing;
//   final Widget? initialEmptyWidget;
//   final Widget? bottomLoadingWidget;
//   final Widget? bottomRetryWidget;
//   final Widget? bottomTrailingWidget;
//   final Widget? initialErrorWidget;

//   const InfiniteMasonryGrid({
//     super.key,
//     required this.fetchItems,
//     required this.itemBuilder,
//     this.initialFetch = true,
//     this.scrollThreshold = 200,
//     // this.limit = 20,
//     this.crossAxisMax = 200,
//     this.mainAxisSpacing = 8,
//     this.crossAxisSpacing = 8,
//     this.initialEmptyWidget,
//     this.bottomLoadingWidget,
//     this.bottomRetryWidget,
//     this.bottomTrailingWidget,
//     this.initialErrorWidget,
//   });

//   @override
//   State<InfiniteMasonryGrid<T>> createState() => _InfiniteMasonryGridState<T>();
// }

// class _InfiniteMasonryGridState<T> extends State<InfiniteMasonryGrid<T>>
//     with WidgetsBindingObserver {
//   final ScrollController _scrollController = ScrollController();
//   final List<T> _items = [];
//   bool _isLoading = false;
//   bool _hasMore = true;
//   int _offset = 0;
//   bool _initialError = false;
//   bool _bottomError = false;
//   bool _needsViewportFill = false;
//   bool _pendingMetricsChange = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     if (widget.initialFetch) _fetchItems(isInitialFetch: true);
//     _scrollController.addListener(_onScroll);
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _scrollController.dispose();
//     super.dispose();
//   }

//   // bool _pendingMetricsChange = false;

//   @override
//   void didChangeMetrics() {
//     super.didChangeMetrics();

//     if (!_scrollController.hasClients || _items.isEmpty) return;

//     // Avoid spamming multiple metric events during rotation
//     if (_pendingMetricsChange) return;
//     _pendingMetricsChange = true;

//     Future.delayed(const Duration(milliseconds: 300), () {
//       _pendingMetricsChange = false;
//       if (!mounted || !_scrollController.hasClients) return;

//       final position = _scrollController.position;
//       final maxExtent = position.maxScrollExtent;
//       final viewportHeight = position.viewportDimension;

//       // Total content height = visible viewport + scrollable content
//       final totalContentHeight = maxExtent + viewportHeight;

//       debugPrint(
//         ' Metrics changed → totalContent: $totalContentHeight, viewport+threshold: ${viewportHeight + widget.scrollThreshold}',
//       );

//       // Fetch more if content is shorter than viewport + threshold
//       if (totalContentHeight < viewportHeight + widget.scrollThreshold &&
//           _hasMore) {
//         debugPrint(' After rotation: content too short — refilling...');
//         _needsViewportFill = true;
//         _checkViewportFill();
//       }
//     });
//   }

//   Future<void> _fetchItems({required bool isInitialFetch}) async {
//     if (_isLoading || !_hasMore) return;

//     setState(() {
//       _isLoading = true;
//       if (!isInitialFetch) _bottomError = false;
//     });

//     try {
//       final (newItems, limit) = await widget.fetchItems(_offset);
//       if (!mounted) return;

//       setState(() {
//         _isLoading = false;
//         if (isInitialFetch) _initialError = false;

//         if (newItems.isEmpty && _items.isEmpty) {
//           _hasMore = false;
//         } else {
//           _items.addAll(newItems);
//           _offset += newItems.length;
//           if (newItems.length < limit) _hasMore = false;
//         }

//         if (isInitialFetch && _hasMore) {
//           _needsViewportFill = true;
//           _checkViewportFill();
//         }
//       });
//     } catch (_) {
//       debugPrint('here in infinite scroll');
//       setState(() {
//         _isLoading = false;
//         if (isInitialFetch) {
//           _initialError = true;
//         } else {
//           _bottomError = true;
//         }
//       });
//     }
//   }

//   void _checkViewportFill() {
//     if (!_needsViewportFill || !_hasMore || _isLoading) return;

//     if (!mounted || !_scrollController.hasClients) return;

//     final position = _scrollController.position;
//     final maxExtent = position.maxScrollExtent; // Scrollable extent
//     final viewportHeight = position.viewportDimension; // Visible height

//     final totalContentHeight = maxExtent + viewportHeight;

//     debugPrint(
//       'Viewport check → totalContentHeight: $totalContentHeight, '
//       'viewport + threshold: ${viewportHeight + widget.scrollThreshold}',
//     );

//     // If content is still smaller than viewport + threshold → fetch more
//     if (totalContentHeight < viewportHeight + widget.scrollThreshold &&
//         _hasMore &&
//         !_isLoading) {
//       _fetchItems(isInitialFetch: false).then((_) => _checkViewportFill());
//     } else {
//       _needsViewportFill = false;
//     }
//   }

//   double _lastScrollOffset = 0;

//   void _onScroll() {
//     if (!_scrollController.hasClients || _isLoading || !_hasMore) return;

//     final position = _scrollController.position;
//     final pixels = position.pixels;

//     final isScrollingDown = pixels > _lastScrollOffset;
//     _lastScrollOffset = pixels;

//     // Trigger fetch only when scrolling down
//     if (isScrollingDown &&
//         pixels >= position.maxScrollExtent - widget.scrollThreshold) {
//       debugPrint('Scroll reached near bottom → fetching more');
//       _fetchItems(isInitialFetch: false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_initialError) {
//       return widget.initialErrorWidget ??
//           Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text("Failed to load items."),
//                 const SizedBox(height: 8),
//                 ElevatedButton(
//                   onPressed: () => _fetchItems(isInitialFetch: true),
//                   child: const Text("Retry"),
//                 ),
//               ],
//             ),
//           );
//     }

//     if (_items.isEmpty && !_isLoading) {
//       return widget.initialEmptyWidget ??
//           const Center(child: Text("No items found"));
//     }

//     return Padding(
//       padding: EdgeInsetsGeometry.symmetric(horizontal: 12),
//       child: CustomScrollView(
//         controller: _scrollController,
//         slivers: [
//           SliverMasonryGrid.extent(
//             // delegate: SliverSimpleGridDelegateWithMaxCrossAxisExtent(
//             //   maxCrossAxisExtent: widget.crossAxisMax, // max width of each item
//             // ),
//             maxCrossAxisExtent: widget.crossAxisMax,
//             mainAxisSpacing: widget.mainAxisSpacing,
//             crossAxisSpacing: widget.crossAxisSpacing,
//             itemBuilder:
//                 (BuildContext context, int index) =>
//                     widget.itemBuilder(context, _items[index], index),
//             // children: ,

//             // delegate: SliverChildBuilderDelegate(
//             //   (context, index) =>
//             //       widget.itemBuilder(context, _items[index], index),
//             //   addAutomaticKeepAlives: true,
//             //   childCount: _items.length,
//             // ),
//           ),
//           SliverToBoxAdapter(child: _buildBottomWidget()),
//         ],
//       ),
//     );
//   }

//   Widget _buildBottomWidget() {
//     if (_isLoading) {
//       return widget.bottomLoadingWidget ??
//           const Padding(
//             padding: EdgeInsets.symmetric(vertical: 16),
//             child: Center(child: CircularProgressIndicator()),
//           );
//     }

//     if (_bottomError) {
//       return widget.bottomRetryWidget ??
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             child: Center(
//               child: ElevatedButton(
//                 onPressed: () => _fetchItems(isInitialFetch: false),
//                 child: const Text("Retry"),
//               ),
//             ),
//           );
//     }

//     if (!_hasMore) {
//       return widget.bottomTrailingWidget ??
//           const Padding(
//             padding: EdgeInsets.symmetric(vertical: 16),
//             child: Center(child: Text("— End of list —")),
//           );
//     }

//     return const SizedBox.shrink();
//   }
// }

// class KeepAliveWidget extends StatefulWidget {
//   final Widget child;
//   const KeepAliveWidget({super.key, required this.child});

//   @override
//   State<KeepAliveWidget> createState() => _KeepAliveWidgetState();
// }

// class _KeepAliveWidgetState extends State<KeepAliveWidget>
//     with AutomaticKeepAliveClientMixin {
//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//     return widget.child;
//   }

//   @override
//   bool get wantKeepAlive => true;
// }
