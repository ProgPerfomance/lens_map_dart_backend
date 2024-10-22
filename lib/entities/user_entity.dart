class UserEntity {
  String? firstName;
  String? lastName;
  String? email;
  String? phone;
  String? password;
  String? countryId;
  String? cityId;
  List? languages;
  List? categories;
  String? dateOfBurn;
  String? description;
  int? type;
  String? uuid;
  UserEntity(
      {required this.categories,
      required this.cityId,
      required this.countryId,
      required this.dateOfBurn,
      required this.description,
      required this.email,
      required this.firstName,
      required this.languages,
      required this.lastName,
      required this.password,
      required this.phone,
      required this.type,
        required this.uuid
  }  );
  Map<String, dynamic> createJson () {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'password': password,
      'country_id': countryId,
      'city_id': cityId,
      'languages': languages,
      'categories': categories,
  'type': type,
      'uuid': uuid,
    };
  }
}
