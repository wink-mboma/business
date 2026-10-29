class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.size,
    required this.color,
    required this.stock,
    this.price,
    this.imageUrl,
  });

  final String id;
  final String size;
  final String color;
  final int stock;
  final double? price;
  final String? imageUrl;

  bool get isAvailable => stock > 0;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.imageUrl,
    this.gallery = const [],
    this.originalPrice,
    this.description = 'A considered essential, designed with clean lines and quality details.',
    this.sizes = const ['One size'],
    this.colors = const ['Default'],
    this.variants = const [],
    this.stockQuantity = 0,
    this.categoryId,
    this.categoryName,
    this.brandId,
    this.hasSizeOptions = false,
    this.hasColorOptions = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    String text(dynamic value, [String fallback = '']) => value == null ? fallback : value.toString();
    double number(dynamic value) => value is num ? value.toDouble() : double.tryParse(text(value)) ?? 0;
    int integer(dynamic value) => value is num ? value.toInt() : int.tryParse(text(value)) ?? 0;

    final rawGallery = json['gallery'];
    final gallery = rawGallery is List
        ? rawGallery.map((e) => text(e)).where((e) => e.isNotEmpty).toList()
        : <String>[];
    final image = text(json['image_url'], gallery.isNotEmpty ? gallery.first : '');
    if (gallery.isEmpty && image.isNotEmpty) gallery.add(image);

    final sizeOptions = <Map<String, dynamic>>[];
    final colorOptions = <Map<String, dynamic>>[];
    final otherOptions = <Map<String, dynamic>>[];
    final rawVariants = json['variants'];
    if (rawVariants is List) {
      for (final raw in rawVariants) {
        if (raw is! Map) continue;
        final v = Map<String, dynamic>.from(raw);
        final type = text(v['type']).trim().toLowerCase();
        final value = text(v['value']).trim();
        if (value.isEmpty) continue;
        if (['size', 'sizes'].contains(type)) {
          sizeOptions.add(v);
        } else if (['color', 'colour', 'colors', 'colours'].contains(type)) {
          colorOptions.add(v);
        } else {
          otherOptions.add(v);
        }
      }
    }

    final sizes = sizeOptions.map((v) => text(v['value'])).toSet().toList();
    final colors = colorOptions.map((v) => text(v['value'])).toSet().toList();
    final variants = <ProductVariant>[];
    final basePrice = number(json['price']);

    // The current admin schema stores each size or colour as a separate option
    // row, not a size+colour stock matrix. Create conservative selectable
    // combinations using the lower of the two option stocks. This avoids
    // advertising more stock than either selected option reports.
    if (sizeOptions.isNotEmpty && colorOptions.isNotEmpty) {
      for (final size in sizeOptions) {
        for (final color in colorOptions) {
          final sizeStock = integer(size['stock']);
          final colorStock = integer(color['stock']);
          final adjustment = number(size['price_adjustment']) + number(color['price_adjustment']);
          variants.add(ProductVariant(
            id: '${text(json['id'])}-${text(size['id'])}-${text(color['id'])}',
            size: text(size['value']),
            color: text(color['value']),
            stock: sizeStock < colorStock ? sizeStock : colorStock,
            price: adjustment == 0 ? null : basePrice + adjustment,
          ));
        }
      }
    } else if (sizeOptions.isNotEmpty) {
      for (final size in sizeOptions) {
        final adjustment = number(size['price_adjustment']);
        variants.add(ProductVariant(
          id: text(size['id'], '${text(json['id'])}-size-${text(size['value'])}'),
          size: text(size['value']), color: 'Default',
          stock: integer(size['stock']),
          price: adjustment == 0 ? null : basePrice + adjustment,
        ));
      }
    } else if (colorOptions.isNotEmpty) {
      for (final color in colorOptions) {
        final adjustment = number(color['price_adjustment']);
        variants.add(ProductVariant(
          id: text(color['id'], '${text(json['id'])}-color-${text(color['value'])}'),
          size: 'One size', color: text(color['value']),
          stock: integer(color['stock']),
          price: adjustment == 0 ? null : basePrice + adjustment,
        ));
      }
    } else {
      // Other variant types are exposed as selectable colour-like options only
      // when no size/colour option is configured in the admin panel.
      for (final option in otherOptions) {
        variants.add(ProductVariant(
          id: text(option['id'], '${text(json['id'])}-${text(option['value'])}'),
          size: 'One size', color: text(option['value']),
          stock: integer(option['stock']),
          price: number(option['price_adjustment']) == 0 ? null : basePrice + number(option['price_adjustment']),
        ));
      }
    }

    final storedVariantsRaw = json['stored_variants'];
    final storedVariants = <ProductVariant>[];
    if (storedVariantsRaw is List) {
      for (final raw in storedVariantsRaw) {
        if (raw is! Map) continue;
        final v = Map<String, dynamic>.from(raw);
        storedVariants.add(ProductVariant(
          id: text(v['id']), size: text(v['size'], 'One size'),
          color: text(v['color'], 'Default'), stock: integer(v['stock']),
          price: v['price'] == null ? null : number(v['price']),
          imageUrl: v['image_url']?.toString(),
        ));
      }
    }
    final storedSizes = json['stored_sizes'] is List
        ? (json['stored_sizes'] as List).map((v) => text(v)).toList()
        : <String>[];
    final storedColors = json['stored_colors'] is List
        ? (json['stored_colors'] as List).map((v) => text(v)).toList()
        : <String>[];
    final original = json['original_price'] == null ? null : number(json['original_price']);
    return Product(
      id: text(json['id']), name: text(json['name'], 'Product'),
      brand: text(json['brand'], 'Mono Store'), price: basePrice,
      imageUrl: image, gallery: gallery, originalPrice: original,
      description: text(json['description'], 'Discover this product from Mono Store.'),
      sizes: storedSizes.isNotEmpty ? storedSizes : (sizes.isEmpty ? const ['One size'] : sizes),
      colors: storedColors.isNotEmpty ? storedColors : (colors.isEmpty ? (otherOptions.isNotEmpty ? otherOptions.map((v) => text(v['value'])).toSet().toList() : const ['Default']) : colors),
      variants: storedVariantsRaw is List ? storedVariants : variants,
      stockQuantity: integer(json['stock_quantity']),
      categoryId: json['category_id']?.toString(),
      categoryName: json['category_name']?.toString(),
      brandId: json['brand_id']?.toString(),
      hasSizeOptions: storedVariantsRaw is List ? storedSizes.isNotEmpty && storedSizes.first != 'One size' : sizeOptions.isNotEmpty,
      hasColorOptions: storedVariantsRaw is List ? storedColors.isNotEmpty && storedColors.first != 'Default' : (colorOptions.isNotEmpty || (sizeOptions.isEmpty && otherOptions.isNotEmpty)),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'price': price,
    'original_price': originalPrice,
    'image_url': imageUrl,
    'gallery': gallery,
    'description': description,
    'stock_quantity': stockQuantity,
    'category_id': categoryId,
    'category_name': categoryName,
    'brand_id': brandId,
    'stored_sizes': sizes,
    'stored_colors': colors,
    'stored_variants': variants.map((v) => {
      'id': v.id, 'size': v.size, 'color': v.color, 'stock': v.stock,
      'price': v.price, 'image_url': v.imageUrl,
    }).toList(),
  };

  final String id;
  final String name;
  final String brand;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  final List<String> gallery;
  final String description;
  final List<String> sizes;
  final List<String> colors;
  final List<ProductVariant> variants;
  final int stockQuantity;
  final String? categoryId;
  final String? categoryName;
  final String? brandId;
  final bool hasSizeOptions;
  final bool hasColorOptions;

  List<String> get images => gallery.isEmpty ? [imageUrl] : gallery;
  bool get hasVariantInventory => variants.isNotEmpty;

  ProductVariant? variantFor(String size, String color) {
    for (final variant in variants) {
      if (variant.size == size && variant.color == color) return variant;
    }
    return null;
  }
}

const sampleProducts = <Product>[
  Product(
    id: '1',
    name: 'Structured Wool Coat',
    brand: 'STUDIO',
    price: 89000,
    originalPrice: 110000,
    imageUrl: 'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?auto=format&fit=crop&w=1000&q=85',
    gallery: [
      'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?auto=format&fit=crop&w=1200&q=90',
      'https://images.unsplash.com/photo-1548624149-fd6c3e9c9f4b?auto=format&fit=crop&w=1200&q=90',
      'https://images.unsplash.com/photo-1548126032-079a0fb0099d?auto=format&fit=crop&w=1200&q=90',
    ],
    sizes: ['XS', 'S', 'M', 'L'],
    colors: ['Black', 'Grey'],
    variants: [
      ProductVariant(id: '1-black-xs', size: 'XS', color: 'Black', stock: 0),
      ProductVariant(id: '1-black-s', size: 'S', color: 'Black', stock: 4),
      ProductVariant(id: '1-black-m', size: 'M', color: 'Black', stock: 7),
      ProductVariant(id: '1-black-l', size: 'L', color: 'Black', stock: 2),
      ProductVariant(id: '1-grey-xs', size: 'XS', color: 'Grey', stock: 3),
      ProductVariant(id: '1-grey-s', size: 'S', color: 'Grey', stock: 5),
      ProductVariant(id: '1-grey-m', size: 'M', color: 'Grey', stock: 0),
      ProductVariant(id: '1-grey-l', size: 'L', color: 'Grey', stock: 1),
    ],
  ),
  Product(
    id: '2',
    name: 'Minimal Knit Sweater',
    brand: 'ESSENTIALS',
    price: 42000,
    imageUrl: 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?auto=format&fit=crop&w=1000&q=85',
    gallery: [
      'https://images.unsplash.com/photo-1576566588028-4147f3842f27?auto=format&fit=crop&w=1200&q=90',
      'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?auto=format&fit=crop&w=1200&q=90',
    ],
    variants: [
      ProductVariant(id: '2-black-s', size: 'S', color: 'Black', stock: 3),
      ProductVariant(id: '2-black-m', size: 'M', color: 'Black', stock: 6),
      ProductVariant(id: '2-black-l', size: 'L', color: 'Black', stock: 0),
      ProductVariant(id: '2-grey-s', size: 'S', color: 'Grey', stock: 4),
      ProductVariant(id: '2-grey-m', size: 'M', color: 'Grey', stock: 2),
      ProductVariant(id: '2-grey-l', size: 'L', color: 'Grey', stock: 1),
      ProductVariant(id: '2-white-s', size: 'S', color: 'White', stock: 0),
      ProductVariant(id: '2-white-m', size: 'M', color: 'White', stock: 5),
      ProductVariant(id: '2-white-l', size: 'L', color: 'White', stock: 2),
    ],
  ),
  Product(
    id: '3',
    name: 'Everyday Tailored Jacket',
    brand: 'STUDIO',
    price: 76000,
    imageUrl: 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?auto=format&fit=crop&w=1000&q=85',
    gallery: [
      'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?auto=format&fit=crop&w=1200&q=90',
      'https://images.unsplash.com/photo-1592878904946-b3cd8ae243d0?auto=format&fit=crop&w=1200&q=90',
    ],
    variants: [
      ProductVariant(id: '3-black-m', size: 'M', color: 'Black', stock: 2),
      ProductVariant(id: '3-black-l', size: 'L', color: 'Black', stock: 4),
      ProductVariant(id: '3-grey-m', size: 'M', color: 'Grey', stock: 0),
      ProductVariant(id: '3-grey-l', size: 'L', color: 'Grey', stock: 3),
    ],
    sizes: ['M', 'L'],
    colors: ['Black', 'Grey'],
  ),
  Product(id: '4', name: 'Classic White Shirt', brand: 'FORM', price: 29500, imageUrl: 'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?auto=format&fit=crop&w=1000&q=85'),
  Product(id: '5', name: 'Relaxed Neutral Trousers', brand: 'ESSENTIALS', price: 38000, imageUrl: 'https://images.unsplash.com/photo-1506629905607-d9d4f5d5e6e8?auto=format&fit=crop&w=1000&q=85'),
  Product(id: '6', name: 'Modern Shoulder Bag', brand: 'FORM', price: 54000, imageUrl: 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?auto=format&fit=crop&w=1000&q=85'),
];
