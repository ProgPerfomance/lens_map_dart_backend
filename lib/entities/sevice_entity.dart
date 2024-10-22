class ServiceEntity {
  String? name;
  String? description;
  String? userId;
  String? id;
  String? imagePath;
  String? ssid;
  double? priceMin;
  double? priceMax;
  String? categoryId;
  String? categoryName;
  ServiceEntity({
    this.id,
    this.name,
    this.userId,
    this.description,
    this.categoryId,
    this.categoryName,
    this.imagePath,
    this.priceMax,
    this.priceMin,
    this.ssid,
  });
  ServiceEntity copyWith({
    id,
    name,
    userId,
    description,
    categoryId,
    categoryName,
    imagePath,
    priceMin,
    ssid,
    priceMax,
  }) {
    return ServiceEntity(
      id: id  ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      userId: userId  ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      imagePath: imagePath ?? this.imagePath,
      priceMax: priceMax ?? this.priceMax,
      priceMin: priceMin ?? this.priceMin,
      ssid: ssid ?? this.ssid,
    );
  }
  Map<String,dynamic> createDBJson() {
    return {
      'name': name,
      'description': description,
      'user_id': userId,
      'category_id': categoryId,
      'price_min': priceMin,
      'price_max': priceMax,
     // 'ssid': ssid,
    };
  }
  ServiceEntity fromApi(Map map) {
    return ServiceEntity(
      name: map['name'],
      description: map['description'],
      priceMin: map['price_min'],
      priceMax: map['price_max'],
      ssid: map['ssid'],
      categoryId: map['category_id'],
      userId: map['user_id'],
    );
  }
}
