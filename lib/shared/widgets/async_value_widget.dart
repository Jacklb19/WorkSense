import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'error_widget.dart';
import 'loading_widget.dart';

class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final Widget Function(Object error, StackTrace? stack)? errorBuilder;
  final Widget? loadingWidget;

  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.builder,
    this.errorBuilder,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
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
