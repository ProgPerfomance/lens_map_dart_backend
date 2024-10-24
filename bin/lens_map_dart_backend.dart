import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:lens_map_dart_backend/entities/location_entity.dart';
import 'package:lens_map_dart_backend/entities/sevice_entity.dart';
import 'package:lens_map_dart_backend/entities/user_entity.dart';
import 'package:lens_map_dart_backend/mail_service.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

void main(List<String> arguments) async {
  var db = Db("mongodb://localhost:27017/lens_map");
  await db.open();

  //await db.collection('locations').insertMany(locations);

  Router router = Router();

  router.get('/countries/<lang>', (Request request, String lang) async {
    // Указываем коллекцию
    var countriesCollection = db.collection('countries');

    // Выполняем запрос с проекцией, получаем только _id и название страны
    var countries = await countriesCollection
        .find(
          where.fields(
            ['_id', 'name_ru', 'name_sp', 'name_en', 'code'],
          ),
        )
        .toList();
    print(countries);
    List responseCountries = [];
    for (var item in countries) {
      responseCountries.add({
        'id': item['_id'],
        'name': item['name_$lang'],
        'code': item['code']
      });
    }
    return Response.ok(jsonEncode(responseCountries),
        headers: {'Content-Type': 'application/json'});
  });

  router.post('/appReviews', (Request request) async {
    var json = await request.readAsString();
    var data = jsonDecode(json);
    await db.collection('app_reviews').insertOne({
      'user_id': data['user_id'],
      'text': data['text'],
      'likes': 0,
      'dislikes': 0,
      'lang': data['lang'],
    });
    return Response.ok('ok');
  });

  router.get('/appReviews', (Request request) async {
    List<Map> appReviews = [];
    final response = await db.collection('app_reviews').find().toList();
    for (var item in response) {
      final userResponse = await db.collection('users').findOne(
          SelectorBuilder().id(ObjectId.fromHexString(item['user_id'])));
      print(userResponse);
      final responseCountry = await db.collection('countries').findOne(
          SelectorBuilder()
              .id(ObjectId.parse(userResponse?['country_id']))
              .fields(['name_ru']));
      // print(responseCountry);
      final responseCity = await db.collection('countries').findOne({
        'cities': {
          '\$elemMatch': {'_id': ObjectId.parse(userResponse?['city_id'])}
        },
      });
      appReviews.add({
        'sender_name': userResponse?['first_name'],
        'sender_full_name':
            '${userResponse?['first_name']} ${userResponse?['last_name']}',
        'user_id': item['user_id'],
        'sender_city_name': responseCity?['cities'][0]['name_ru'],
        'sender_country_name': responseCountry?['name_ru'],
        'text': item['text'],
        'likes': item['likes'],
        'dislikes': item['dislikes'],
        'lang': item['lang'],
      });
    }
    print(response);
    return Response.ok(jsonEncode(appReviews),
        headers: {'Content-Type': 'application/json'});
  });

  router.get('/sendAuthCode', (Request request) async {
    int code = Random().nextInt(8888) + 1111;
    sendMail('jekcatpopov@mail.ru', '$code');
    return Response.ok('$code');
  });

  router.get('/searchCities/<query>/<lang>',
      (Request request, String query, String lang) async {
        requestLog('GET', '/searchCities/$query/$lang', null);
    String decodedData = Uri.decodeComponent(query);
    print(decodedData);

    // Найдем все страны, где есть города, совпадающие с запросом
    final response = await db.collection('countries').find({
      'cities': {
        '\$elemMatch': {
          'name_$lang': {'\$regex': decodedData, '\$options': 'i'},
        }
      },
    }).toList();

    print(response.length);
    List cities = [];
    for (var country in response) {
      for (var city in country['cities']) {
        if (RegExp(decodedData, caseSensitive: false)
            .hasMatch(city['name_$lang'])) {
          cities.add({
            'name': city['name_$lang'],
            'id': city['_id'],
            'lat': city['lat'],
            'long': city['long']
          });
        }
      }
    }

    if (cities.isEmpty) {
      return Response.notFound('No matching cities found');
    }

    return Response.ok(jsonEncode(cities),
        headers: {'Content-Type': 'application/json'});
  });

  router.get('/categories/<lang>', (Request request, String lang) async {
    requestLog('GET', '/categories/$lang', null);
    final response = await db.collection('categories').find().toList();
    List categories = [];

    for (var item in response) {
      categories.add({'id': item['_id'], 'name': item['name_$lang']});
    }
    return Response.ok(jsonEncode(categories),
        headers: {'Content-Type': 'application/json'});
  });

  router.get('/cities/<country>/<lang>',
      (Request request, String country, String lang) async {
        requestLog('GET', '/cities/$country/$lang', null);
    String decodedCountry = Uri.decodeComponent(country);

    var countryData = await db
        .collection('countries')
        .findOne(SelectorBuilder().eq('code', decodedCountry).limit(100));

    if (countryData == null) {
      return Response.notFound('Country not found');
    }
    var cities;
    var topCities;
    cities = countryData['cities']
        .map((city) => {
              'name': city['name_$lang'],
              'id': city['_id'],
              'lat': city['lat'],
              'long': city['long']
            })
        .toList();
    topCities = countryData['top_cities']
        .map((city) => {
              'name': city['name_$lang'],
              'id': city['_id'],
              'lat': city['lat'],
              'long': city['long']
            })
        .toList();

    return Response.ok(jsonEncode({'cities': cities, 'top_cities': topCities}),
        headers: {'Content-Type': 'application/json'});
  });

  router.post('/auth/<lang>', (Request request, String lang) async {
    String langDec = Uri.decodeComponent(lang);
    var json = await request.readAsString();
    var data = jsonDecode(json);
    requestLog('POST', '/auth/$lang', data);
    final response = await db.collection('users').findOne(SelectorBuilder()
            .eq('email', data['email'] ?? '')
            .eq('password', data['password'] ?? '')
            .fields([
          '_id',
          'first_name',
          'last_name',
          'email',
          'country_id',
          'city_id',
          'languages',
          'categories',
          'type',
          'uuid',
          'phone'
        ]));
    print(response);
    if (response == null) {
      return Response.ok(
          jsonEncode(
            {'data': null},
          ),
          headers: {'Content-Type': 'application/json'});
    }
    final responseCountry = await db.collection('countries').findOne(
        SelectorBuilder()
            .id(ObjectId.parse(response['country_id']))
            .fields(['name_$langDec']));
    // print(responseCountry);
    final responseCity = await db.collection('countries').findOne({
      'cities': {
        '\$elemMatch': {'_id': ObjectId.parse(response['city_id'])}
      },
    });
    print(responseCity?['cities'][0]['name_$langDec']);
    print(responseCity?['name_$langDec']);
    Map responseMap = {
      '_id': response['_id'],
      'city_name': responseCity?['cities'][0]['name_$langDec'],
      'city': responseCity?['cities'][0],
      'country_name': responseCountry?['name_$langDec'],
      'first_name': response['first_name'],
      'last_name': response['last_name'],
      'email': response['email'],
      'country_id': response['country_id'],
      'city_id': response['city_id'],
      'languages': response['languages'],
      'categories': response['categories'],
      'type': response['type'],
      'uuid': response['uuid'],
      'phone': response['phone'],
    };
    return Response.ok(
        jsonEncode(
          {'data': responseMap},
        ),
        headers: {'Content-Type': 'application/json'});
  });

  router.post('/location', (Request request) async {
    var json = await request.readAsString();
    var data = jsonDecode(json);
    requestLog('POST', '/locations', data);
    String uuid = Uuid().v1();
    LocationEntity locationEntity = LocationEntity(
      long: data['long'],
      lat: data['lat'],
      countryId: data['coutry_id'],
      cityId: data['city_id'],
      createrId: data['uid'],
      address: data['address'],
      lid: uuid,
      nameRu: data['name_ru'],
    );
    db.collection('locations').insertOne({});
  });

  router.get('/locations/<city>/<lang>', (Request request, String city, String lang) async {
    requestLog('GET', '/locations/$city/$lang', null);
    print(request.handlerPath);
    final response = await db.collection('locations').find(SelectorBuilder().eq('city_id', city)).toList();
    final responseList = [];
    for(var item in response) {
      responseList.add({
        'name': item['name_$lang'],
        'description': item['description_$lang'],
        'lat': item['lat'],
        'long': item['long'],
        'image_url': item['image_url'],
        'address': item['address'],
      });
    }
    return Response.ok(jsonEncode(responseList), headers: {'Content-Type': 'application/json'});
  });



  router.post('/services', (Request request) async {
    var json = await request.readAsString();
    var data = jsonDecode(json);
    requestLog('POST', '/services', data);
    print(data);
    ServiceEntity serviceEntity = ServiceEntity().fromApi(data);
    String ssid = Uuid().v1();
    await db
        .collection('services')
        .insertOne(serviceEntity.copyWith(ssid: ssid).createDBJson());
    return Response.ok('created');
  });

  router.put('/services/<id>', (Request request, String id) async {
    var json = await request.readAsString();
    var data = jsonDecode(json);
    requestLog('PUT', '/services/$id', data);
    await db.collection('services').updateOne(
        SelectorBuilder().id(ObjectId.fromHexString(id)),
        modify
            .set('name', data['name'])
            .set('description', data['description'])
            .set('price_min', data['price_min'])
            .set('price_max', data['price_max'])
            .set('category_id', data['category_id']));
    return Response.ok('updated');
  });

  router.delete('/services/<id>', (Request request, String id) async {
    requestLog('DELETE', '/services/$id', null);
    await db
        .collection('services')
        .deleteOne(SelectorBuilder().id(ObjectId.fromHexString(id)));
    return Response.ok('deleted');
  });

  router.get('/news/<lang>', (Request request, String lang) async {
    requestLog('GET', '/news', null);
    final response =
        await db.collection('news').find(SelectorBuilder().eq('lang', lang)).toList();
    return Response.ok(jsonEncode(response),  headers: {'Content-Type': 'application/json'});
  });

  router.post('/news', (Request request) async {
    var json = await request.readAsString();
    var data = jsonDecode(json);
    requestLog('POST', '/news', data);
    String nnid = Uuid().v1();
    if (data['img'] != null) {
      //   File file = File();
      File file = await File('data/news/news$nnid.jpeg');
      file.create();
      await file.open(mode: FileMode.write);
      List<int> imageList = base64Decode(data['img']);
      await file.writeAsBytes(imageList);
      return Response.ok('created');
    }
    Map<String, dynamic>
    dData = {
      'title': data['title'],
      'nnid': nnid,
      'body': data['body'],
      'lang': data['lang'],
      'timestamp': DateTime.now().toIso8601String(),
    };
    await db.collection('news').insertOne(dData);
  });

  router.get('/services/<uid>/<lang>',
      (Request request, String uid, String lang) async {
        requestLog('GET', '/services/$uid/$lang', null);
    final response = await db
        .collection('services')
        .find(SelectorBuilder().eq('user_id', uid))
        .toList();
    List responseList = [];
    for (var item in response) {
      final categoryName = await db.collection('categories').findOne(
          SelectorBuilder()
              .id(ObjectId.fromHexString(item['category_id']))
              .fields(['name_$lang', 'image_url']));
      print(categoryName);
      responseList.add({
        'name': item['name'],
        'id': item['_id'],
        'image_url': categoryName?['image_url'],
        // 'user_id': item['user_id'],
        'price_min': item['price_min'],
        'price_max': item['price_max'],
        'category_name': categoryName?['name_$lang'],
        'category_id': item['category_id'],
        'description': item['description'],
      });
    }
    return Response.ok(jsonEncode(responseList),
        headers: {'Content-Type': 'application/json'});
  });

  router.post('/createUser', (Request request) async {
    var json = await request.readAsString();
    var data = jsonDecode(json);
    requestLog('POST', '/createUser', data);
    var userData = data['data'];
    String uuid = Uuid().v1();
    if (data['avatar'] != null) {
      //   File file = File();
      File file = await File('data/avatars/avatar_$uuid.jpeg');
      file.create();
      await file.open(mode: FileMode.write);
      print(data['avatar']);
      List<int> imageList = base64Decode(data['avatar']);
      await file.writeAsBytes(imageList);
    }
    UserEntity userEntity = UserEntity(
        uuid: uuid,
        categories: userData['categories'],
        cityId: userData['city_id'],
        countryId: userData['country_id'],
        dateOfBurn: userData['date_of_burn'],
        description: userData['description'],
        email: userData['email'],
        firstName: userData['first_name'],
        languages: userData['languages'],
        lastName: userData['last_name'],
        password: userData['password'],
        phone: userData['phone'],
        type: userData['type']);
    await db.collection('users').insertOne(userEntity.createJson());
    return Response.ok(uuid);
  });

  router.get('/getUserAvatar/<uid>', (Request request, String uid) async {
    requestLog('GET', 'getUserAvatar/$uid', null);
    final file = File('data/avatars/avatar_$uid.jpeg');
    final image = await file.readAsBytes();
    return Response.ok(image, headers: {'Content-Type': 'image/jpeg'});
  });

  router.get('/newsImage/<id>', (Request request, String id) async {
    requestLog('GET', 'newsImage/$id', null);
    final file = File('data/news/news_$id.jpeg');
    final image = await file.readAsBytes();
    return Response.ok(image, headers: {'Content-Type': 'image/jpeg'});
  });

  var server = await serve(router, '0.0.0.0', 2302);
  print('Server listening on port ${server.port}');
}


List<Map<String, dynamic>> locations = [
  LocationEntity(
    photographs: [],
    countryId: '6707ed37d46c6cc833000000',
    cityId: '6707ed37d46c6ac833000000',
    nameEn: 'Temple of the Holy Family (Sagrada Familia)',
    nameRu: 'Храм Святого Семейства (Саграда Фамилия)',
    nameSp: 'Templo de la Sagrada Familia',
    address: 'Carrer de Mallorca, 401, 08013 Barcelona, Spain',
    lat: 41.403191,
    long: 2.174840,
    lid: Uuid().v1(),
    descriptionRu: 'Этот шедевр Антонио Гауди отличается уникальной архитектурой. Его впечатляющие фасады и интерьеры создают идеальные условия для создания художественных фотографий.',
    descriptionEn: 'This masterpiece by Antoni Gaudí stands out for its unique architecture. Its impressive facades and interiors create perfect conditions for artistic photography.',
    descriptionSp: 'Esta obra maestra de Antoni Gaudí se destaca por su arquitectura única. Sus impresionantes fachadas e interiores crean condiciones perfectas para la fotografía artística.',
    imageUrl: 'https://albergueesplaibarcelona.com/wp-content/uploads/2020/03/sagrada-familia-552084_1920.jpg',
  ).createDBJson(),
];

void requestLog(method, point, data) {
  print('${DateTime.now()}\n$method\n$point\nData: $data');
}