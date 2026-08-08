import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/article_card.dart';
import '../../components/state_view.dart';
import '../../constants/ui_constants.dart';
import '../../extensions/context_extensions.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/article_list_view_model.dart';
import '../../widgets/app_loader.dart';

/// EXAMPLE VIEW — a paginated, searchable list.
///
/// The pattern to copy: the widget owns scroll and text controllers (UI
/// concerns) and delegates everything else to the view model. There is no
/// `try/catch`, no loading boolean and no error string in this file —
/// [StateView] renders whatever state the view model reports.
class ArticleListView extends StatefulWidget {
  const ArticleListView({super.key});

  @override
  State<ArticleListView> createState() => _ArticleListViewState();
}

class _ArticleListViewState extends State<ArticleListView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Prefetches one screen-height early so the user rarely sees the spinner.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      context.read<ArticleListViewModel>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ArticleListViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.articlesTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: UiConstants.listPadding,
              child: SearchBar(
                controller: _searchController,
                hintText: context.l10n.commonRetry,
                leading: const Icon(Icons.search),
                onChanged: viewModel.search,
                trailing: [
                  if (viewModel.searchQuery.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _searchController.clear();
                        viewModel.clearSearch();
                      },
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ),
            Expanded(
              child: StateView(
                viewModel: viewModel,
                onRetry: viewModel.load,
                builder: (context) => RefreshIndicator(
                  onRefresh: viewModel.refresh,
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: UiConstants.listPadding,
                    // One extra row for the pagination spinner.
                    itemCount:
                        viewModel.articles.length +
                        (viewModel.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: UiConstants.spaceSm),
                    itemBuilder: (context, index) {
                      if (index >= viewModel.articles.length) {
                        return const Padding(
                          padding: EdgeInsets.all(UiConstants.spaceMd),
                          child: AppLoader(size: 24),
                        );
                      }
                      final article = viewModel.articles[index];
                      return ArticleCard(
                        article: article,
                        onTap: () => context.pushNamed(
                          AppRoutes.articleDetailName,
                          pathParameters: {'id': article.id},
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
