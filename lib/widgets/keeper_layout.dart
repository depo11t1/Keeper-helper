import 'dart:math' as math;

import 'package:flutter/widgets.dart';

double keeperPageMaxWidth(
  BuildContext context, {
  double maxWidth = 860,
}) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  if (screenWidth >= 1400) {
    return maxWidth;
  }
  if (screenWidth >= 900) {
    return maxWidth;
  }
  return screenWidth;
}

EdgeInsets keeperPagePadding(
  BuildContext context, {
  double horizontal = 20,
  double top = 0,
  double bottom = 0,
  double maxWidth = 860,
}) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final contentWidth = keeperPageMaxWidth(context, maxWidth: maxWidth);
  final sidePadding = math.max(horizontal, (screenWidth - contentWidth) / 2);
  return EdgeInsets.fromLTRB(sidePadding, top, sidePadding, bottom);
}

class KeeperCenteredBody extends StatelessWidget {
  const KeeperCenteredBody({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.maxWidth = 860,
  });

  final Widget child;
  final EdgeInsets padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: keeperPageMaxWidth(context, maxWidth: maxWidth),
        ),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
