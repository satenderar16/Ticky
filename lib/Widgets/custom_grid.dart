import 'package:flutter/material.dart';

class CustomGrid extends StatelessWidget {
  final List<Widget> children;
  final double? childWidth; // max width per child
  final int? crossAxisCount; // alternatively, specify number of columns
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  const CustomGrid({
    Key? key,
    required this.children,
    this.childWidth,
    this.crossAxisCount,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final parentWidth = constraints.maxWidth;

        // Determine number of columns
        int columns;
        if (crossAxisCount != null) {
          columns = crossAxisCount!.clamp(1, children.length);
        } else if (childWidth != null && childWidth! > 0) {
          columns = (parentWidth / (childWidth! + crossAxisSpacing))
              .floor()
              .clamp(1, children.length);
        } else {
          columns = 1;
        }

        // Actual width for each child
        final actualChildWidth =
            (parentWidth - (columns - 1) * crossAxisSpacing) / columns;

        // Distribute children column-first
        final columnItems = List.generate(columns, (_) => <Widget>[]);
        for (int i = 0; i < children.length; i++) {
          final col = i % columns;
          columnItems[col].add(children[i]);
        }

        // Build Row of Columns
        return Row(
          mainAxisSize: MainAxisSize.min, // center the row
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(columns, (colIndex) {
            final col = columnItems[colIndex];
            return Padding(
              padding: EdgeInsets.only(
                right: colIndex < columns - 1 ? crossAxisSpacing : 0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(col.length, (rowIndex) {
                  final child = col[rowIndex];
                  // Apply bottom spacing only if it's NOT the last item in the column
                  final isLast = rowIndex == col.length - 1;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: isLast ? 0 : mainAxisSpacing,
                    ),
                    child: SizedBox(width: actualChildWidth, child: child),
                  );
                }),
              ),
            );
          }),
        );
      },
    );
  }
}
