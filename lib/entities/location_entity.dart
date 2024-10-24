class LocationEntity {
  String? id;
  String? name;
  String? address;
  double? lat;
  double? long;
  String? lid;
  String? createrId;
  String? descriptionRu;
  String? descriptionSp;
  String? descriptionEn;
  List? photographs;
  String? countryId;
  String? cityId;
  String? nameRu;
  String? nameEn;
  String? nameSp;
  String? imageUrl;
  LocationEntity({
    this.long,
    this.countryId,
    this.lat,
    this.cityId,
    this.id,
    this.name,
    this.address,
    this.createrId,
    this.lid,
    this.photographs,
    this.nameEn,
    this.nameRu,
    this.nameSp,
    this.descriptionEn,
    this.descriptionRu,
    this.descriptionSp,
    this.imageUrl,
});
  Map<String,dynamic> createDBJson() => {
    // 'id': id,
   // 'name': name,
    'address': address,
    'lat': lat,
    'long': long,
    'lid': lid,
    'creater_id': createrId,
    'photographs': photographs,
    'country_id': countryId,
    'city_id': cityId,
    'name_ru': nameRu,
    'name_sp': nameSp,
    'name_en': nameEn,
    'description_en': descriptionEn,
    'description_ru': descriptionRu,
    'description_sp': descriptionSp,
    'image_url': imageUrl,
  };
}