import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/shared/widgets/error_widget.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';

/// Generic widget that handles AsyncValue states
class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final Widget? loadingWidget;
  final Widget Function(Object error, StackTrace? stack)? errorBuilder;

  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: builder,
      loading: () => loadingWidget ?? const AppLoadingWidget(),
      error: (error, stack) {
        if (errorBuilder != null) {
          return errorBuilder!(error, stack);
        }
        return AppErrorWidget(message: error.toString());
      },
    );
  }
}

/// AsyncValue widget that shows data immediately while refreshing
class AsyncValueSliver<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;

  const AsyncValueSliver({
    super.key,
    required this.value,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      data: builder,
      loading: () => const SliverToBoxAdapter(
        child: AppLoadingWidget(),
      ),
      error: (error, _) => SliverToBoxAdapter(
        child: AppErrorWidget(message: error.toString()),
      ),
    );
  }
}
