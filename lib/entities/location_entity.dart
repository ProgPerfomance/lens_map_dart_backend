class LocationEntity {
  String? id;
  String? name;
  String? address;
  double? lat;
  double? long;
  String? lid;
  String? createrId;
  List? photographs;
  String? countryId;
  String? cityId;
  String? nameRu;
  String? nameEn;
  String? nameSp;
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
    this.nameSp
});
  Map createDBJson() => {
    // 'id': id,
    'name': name,
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
  };
}