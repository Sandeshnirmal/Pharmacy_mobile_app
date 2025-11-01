import 'product_model.dart';

class PaginatedProductsResponse {
  final List<ProductModel> products;
  final int currentPage;
  final int totalPages;
  final int totalCount;

  PaginatedProductsResponse({
    required this.products,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
  });

  factory PaginatedProductsResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedProductsResponse(
      products: (json['results'] as List)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: json['current_page'] as int? ?? 1,
      totalPages: json['total_pages'] as int? ?? 1,
      totalCount: json['count'] as int? ?? 0,
    );
  }
}
