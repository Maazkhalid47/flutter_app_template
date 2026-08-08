/// One page of a list, plus what the UI needs to load the next one.
///
/// Every paginated endpoint returns this, so infinite-scroll logic is written
/// once in the view model instead of per screen.
class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    this.totalCount,
  });

  const PaginatedResult.empty({this.pageSize = 0})
    : items = const [],
      page = 1,
      totalCount = 0;

  final List<T> items;

  /// 1-based page index.
  final int page;
  final int pageSize;

  /// Total items across all pages, when the server reports it.
  final int? totalCount;

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  /// A short page is the reliable end-of-list signal even when the server sends
  /// no total count.
  bool get hasMore {
    final total = totalCount;
    if (total != null) return page * pageSize < total;
    return items.length >= pageSize;
  }

  int get nextPage => page + 1;

  /// Appends the next page, keeping this page's items first.
  PaginatedResult<T> merge(PaginatedResult<T> next) => PaginatedResult<T>(
    items: [...items, ...next.items],
    page: next.page,
    pageSize: next.pageSize,
    totalCount: next.totalCount ?? totalCount,
  );

  PaginatedResult<R> mapItems<R>(R Function(T item) transform) =>
      PaginatedResult<R>(
        items: items.map(transform).toList(),
        page: page,
        pageSize: pageSize,
        totalCount: totalCount,
      );
}
