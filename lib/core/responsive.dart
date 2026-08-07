import 'package:flutter/widgets.dart';

/// Simple, dependency-free responsive helpers.
enum FormFactor { mobile, tablet, desktop }

class Breakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;
}

extension ResponsiveContext on BuildContext {
  double get width => MediaQuery.sizeOf(this).width;

  FormFactor get formFactor {
    final w = width;
    if (w >= Breakpoints.desktop) return FormFactor.desktop;
    if (w >= Breakpoints.tablet) return FormFactor.tablet;
    return FormFactor.mobile;
  }

  bool get isMobile => formFactor == FormFactor.mobile;
  bool get isTablet => formFactor == FormFactor.tablet;
  bool get isDesktop => formFactor == FormFactor.desktop;
  bool get isWide => width >= Breakpoints.tablet;

  /// Sensible number of grid columns for stat cards.
  int gridColumns({int mobile = 2, int tablet = 3, int desktop = 4}) {
    switch (formFactor) {
      case FormFactor.desktop:
        return desktop;
      case FormFactor.tablet:
        return tablet;
      case FormFactor.mobile:
        return mobile;
    }
  }
}

/// Centers content and caps its width on large screens.
///
/// Implemented with plain [Padding] (not Center/ConstrainedBox) so it is safe
/// to wrap a scrolling ListView — a Center around a ListView collapses it.
class ContentContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  const ContentContainer({
    super.key,
    required this.child,
    this.maxWidth = 1100,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final extra = (w.isFinite && w > maxWidth) ? (w - maxWidth) / 2 : 0.0;
        return Padding(
          padding: EdgeInsets.only(left: extra, right: extra) + padding,
          child: child,
        );
      },
    );
  }
}
