import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';
import '../extensions/context_extensions.dart';
import '../models/article.dart';
import '../utils/formatters.dart';

/// EXAMPLE COMPONENT — a list row for [Article].
///
/// Note the difference from `widgets/`: this one knows about a domain model.
/// That is exactly what makes it a component rather than a widget, and why it
/// lives here. It still contains no business logic — it takes a model and a
/// callback, and renders.
class ArticleCard extends StatelessWidget {
  const ArticleCard({required this.article, this.onTap, super.key});

  final Article article;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final publishedAt = article.publishedAt;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UiConstants.radiusLg),
        child: Padding(
          padding: UiConstants.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                article.title,
                style: context.textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (article.excerpt.isNotEmpty) ...[
                const SizedBox(height: UiConstants.spaceXs),
                Text(
                  article.excerpt,
                  style: context.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (publishedAt != null) ...[
                const SizedBox(height: UiConstants.spaceSm),
                Text(
                  Formatters.relative(
                    publishedAt,
                    locale: context.locale.languageCode,
                  ),
                  style: context.textTheme.labelSmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
