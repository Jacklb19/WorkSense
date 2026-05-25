import 'package:flutter/material.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_spacing.dart';

enum AppContentWidth {
  form,
  list,
  dashboard,
  full,
}

class AppContentConstrainer extends StatelessWidget {
  const AppContentConstrainer({
    super.key,
    required this.child,
    this.width = AppContentWidth.list,
    this.maxWidth,
    this.padding,
    this.center = true,
  });

  final Widget child;
  final AppContentWidth width;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool center;

  double _effectiveMaxWidth(BuildContext context) {
    if (maxWidth != null) return maxWidth!;
    switch (width) {
      case AppContentWidth.form:
        return AppSpacing.formMaxWidth(context);
      case AppContentWidth.list:
        return AppSpacing.listMaxWidth(context);
      case AppContentWidth.dashboard:
        return AppSpacing.dashboardMaxWidth(context);
      case AppContentWidth.full:
        return double.infinity;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mw = _effectiveMaxWidth(context);
    final effectivePadding = padding ?? AppSpacing.screenPadding(context);

    Widget constrained = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: mw),
      child: Padding(
        padding: effectivePadding,
        child: child,
      ),
    );

    if (center) {
      constrained = Center(child: constrained);
    }

    return constrained;
  }
}

class AppSliverContentConstrainer extends StatelessWidget {
  const AppSliverContentConstrainer({
    super.key,
    required this.child,
    this.width = AppContentWidth.list,
    this.maxWidth,
    this.padding,
  });

  final Widget child;
  final AppContentWidth width;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final mw = maxWidth ?? _sliverMaxWidth(context);
    final effectivePadding = padding ?? AppSpacing.screenPadding(context);

    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: mw),
          child: Padding(
            padding: effectivePadding,
            child: child,
          ),
        ),
      ),
    );
  }

  double _sliverMaxWidth(BuildContext context) {
    switch (width) {
      case AppContentWidth.form:
        return AppSpacing.formMaxWidth(context);
      case AppContentWidth.list:
        return AppSpacing.listMaxWidth(context);
      case AppContentWidth.dashboard:
        return AppSpacing.dashboardMaxWidth(context);
      case AppContentWidth.full:
        return double.infinity;
    }
  }
}

class AppResponsiveGrid extends StatelessWidget {
  const AppResponsiveGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.childAspectRatio = 1.0,
    this.mainAxisExtent,
    this.crossAxisSpacing = AppDimensions.spacingXxl,
    this.mainAxisSpacing = AppDimensions.spacingXxl,
    this.padding,
  });

  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double childAspectRatio;
  final double? mainAxisExtent;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = AppSpacing.gridCrossAxisCount(
          context,
          mobile: mobileColumns,
          tablet: tabletColumns,
          desktop: desktopColumns,
        );

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: padding ?? EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: childAspectRatio,
            mainAxisExtent: mainAxisExtent,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
          ),
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}