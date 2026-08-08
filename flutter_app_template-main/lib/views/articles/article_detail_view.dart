import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/responsive_layout.dart';
import '../../constants/ui_constants.dart';
import '../../core/result.dart';
import '../../extensions/context_extensions.dart';
import '../../models/article.dart';
import '../../repositories/article_repository.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_error_view.dart';
import '../../widgets/app_loader.dart';

/// EXAMPLE VIEW — a detail screen loaded by id.
///
/// This one uses a [FutureBuilder] against the repository rather than a view
/// model, because there is a single read and no user interaction to manage.
/// That is a legitimate choice; adding a view model per screen out of habit is
/// ceremony. Introduce one the moment the screen gains state — editing,
/// refreshing, or more than one request.
class ArticleDetailView extends StatefulWidget {
  const ArticleDetailView({required this.articleId, super.key});

  final String articleId;

  @override
  State<ArticleDetailView> createState() => _ArticleDetailViewState();
}

class _ArticleDetailViewState extends State<ArticleDetailView> {
  late Future<Result<Article>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// The future is created once and held in state — creating it inside `build`
  /// re-fires the request on every rebuild.
  void _load() {
    _future = context.read<ArticleRepository>().fetchArticle(widget.articleId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: context.pop)),
      body: SafeArea(
        child: FutureBuilder<Result<Article>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const AppLoader.fullscreen();
            }
            final result = snapshot.data;
            if (result == null) {
              return const AppLoader.fullscreen();
            }
            return result.when(
              failure: (exception) => AppErrorView(
                exception: exception,
                onRetry: () => setState(_load),
              ),
              success: (article) => _ArticleBody(article: article),
            );
          },
        ),
      ),
    );
  }
}

class _ArticleBody extends StatelessWidget {
  const _ArticleBody({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final publishedAt = article.publishedAt;

    return SingleChildScrollView(
      child: ContentContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(article.title, style: context.textTheme.headlineSmall),
            if (publishedAt != null) ...[
              const SizedBox(height: UiConstants.spaceXs),
              Text(
                Formatters.dateTime(
                  publishedAt,
                  locale: context.locale.languageCode,
                ),
                style: context.textTheme.labelMedium,
              ),
            ],
            const SizedBox(height: UiConstants.spaceLg),
            Text(article.body, style: context.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
