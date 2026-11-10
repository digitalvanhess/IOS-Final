/// Product from the public REST API https://fakestoreapi.com/products (LW10).
///
/// Prices come from the API in US dollars. The app works in tenge, so
/// [priceKzt] converts them with a fixed demo rate (see [usdToKzt]).
class Product {
  /// Fixed demo exchange rate, 1 USD in ₸. A real app would load it from a
  /// currency API; a constant keeps the lab offline-safe and predictable.
  static const usdToKzt = 520;

  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String imageUrl;
  final double rating;
  final int reviewCount;

  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
  });

  /// Type-safe parsing with null-safe fallbacks.
  ///
  /// JSON numbers arrive as `int` or `double` depending on the value
  /// (`109.95` vs `22`), so every number is read as `num` first and then
  /// converted. A direct `as double` would crash on `22`.
  factory Product.fromJson(Map<String, dynamic> json) {
    final rating = json['rating'] is Map<String, dynamic>
        ? json['rating'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return Product(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Без названия',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'other',
      imageUrl: json['image'] as String? ?? '',
      rating: (rating['rate'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (rating['count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Price in tenge, rounded to whole ₸.
  int get priceKzt => (price * usdToKzt).round();

  /// Photos for the detail carousel. The API returns one image per
  /// product, so the gallery shows it in three framings (whole item,
  /// close-up top, close-up bottom).
  List<String> get gallery => [imageUrl, imageUrl, imageUrl];

  /// Deep link for the share sheet.
  String get deepLink => 'narxoz://store/product/$id';

  /// Russian label for the API category.
  String get categoryLabel => switch (category) {
    'electronics' => 'Электроника',
    'jewelery' => 'Украшения',
    "men's clothing" => 'Мужская одежда',
    "women's clothing" => 'Женская одежда',
    _ => category,
  };
}
