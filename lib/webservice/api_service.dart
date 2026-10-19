import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/section_model.dart';
import '../models/banner_model.dart';
import '../models/type_model.dart';
import '../models/detail_model.dart';
import '../models/tv_login_model.dart';
import '../utils/constant.dart';

class TVApiService {
  static final TVApiService _instance = TVApiService._internal();
  factory TVApiService() => _instance;

  late final Dio _dio;

  TVApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Constant.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Api-Token': Constant.apiToken, // Required by Laravel middleware ApiAuthToken
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint("[TV API] $obj"),
        ),
      );
    }
  }

  // 1. Fetch Types (Movies, Series, Anime, etc.)
  Future<TypeListModel> getTypes() async {
    try {
      final response = await _dio.post(
        'get_type',
        data: {
          'user_id': Constant.userId ?? 0,
          'device_id': Constant.deviceId,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        return TypeListModel.fromJson(data);
      }
    } catch (e) {
      debugPrint("Error getTypes: $e");
    }
    return TypeListModel(status: 400, result: []);
  }

  // 2. Fetch Featured Banner ('get_banner')
  Future<BannerListModel> getBanners({int isHomeScreen = 1, int typeId = 0}) async {
    try {
      final response = await _dio.post(
        'get_banner',
        data: {
          'user_id': Constant.userId ?? 0,
          'type_id': typeId,
          'is_home_screen': isHomeScreen,
          'device_id': Constant.deviceId,
          'is_kids_profile': 0,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        return BannerListModel.fromJson(data);
      }
    } catch (e) {
      debugPrint("Error getBanners: $e");
    }
    return BannerListModel(status: 400, result: []);
  }

  // 3. Fetch Horizontal Sections ('section_list')
  Future<SectionListModel> getSections({
    int isHomeScreen = 1,
    int typeId = 0,
    int pageNo = 1,
  }) async {
    try {
      final response = await _dio.post(
        'section_list',
        data: {
          'user_id': Constant.userId ?? 0,
          'type_id': typeId,
          'is_home_screen': isHomeScreen,
          'device_id': Constant.deviceId,
          'is_kids_profile': 0,
          'page_no': pageNo,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        return SectionListModel.fromJson(data);
      }
    } catch (e) {
      debugPrint("Error getSections: $e");
    }
    return SectionListModel(status: 400, result: []);
  }

  // 4. Fetch Details ('content_detail')
  Future<ContentDetailModel> getContentDetail({
    required int id,
    required int videoType,
    int typeId = 0,
  }) async {
    try {
      final response = await _dio.post(
        'content_detail',
        data: {
          'type_id': typeId,
          'video_type': videoType,
          'video_id': id,
          'user_id': Constant.userId ?? 0,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        return ContentDetailModel.fromJson(data);
      }
    } catch (e) {
      debugPrint("Error getContentDetail: $e");
    }
    return ContentDetailModel(status: 400, result: null);
  }

  // 5. Fetch Episodes by Season ('get_video_by_season_id')
  Future<List<EpisodeItem>> getEpisodesBySeason({
    required int showId,
    required int seasonId,
  }) async {
    try {
      final response = await _dio.post(
        'get_video_by_season_id',
        data: {
          'show_id': showId,
          'season_id': seasonId,
          'user_id': Constant.userId ?? 0,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        if (data['result'] != null && data['result'] is List) {
          return (data['result'] as List).map((i) => EpisodeItem.fromJson(i)).toList();
        }
      }
    } catch (e) {
      debugPrint("Error getEpisodesBySeason: $e");
    }
    return [];
  }

  // 6. Search Content ('search_content')
  Future<List<ContentItem>> search({required String query}) async {
    try {
      final response = await _dio.post(
        'search_content',
        data: {
          'title': query,
          'user_id': Constant.userId ?? 0,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        if (data['result'] != null && data['result'] is List) {
          return (data['result'] as List).map((i) => ContentItem.fromJson(i)).toList();
        }
      }
    } catch (e) {
      debugPrint("Error search: $e");
    }
    return [];
  }

  // 7. TV Activation Login (Generate Code: 'get_tv_login_code')
  Future<TVLoginCodeModel> getTvLoginCode() async {
    try {
      final response = await _dio.post('get_tv_login_code', data: {});
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        return TVLoginCodeModel.fromJson(data);
      }
    } catch (e) {
      debugPrint("Error getTvLoginCode: $e");
    }
    return TVLoginCodeModel(status: 400, result: []);
  }

  // 8. TV Activation Login (Poll Status: 'check_tv_login')
  Future<TVUserData?> checkTvLogin({required String uniqueCode}) async {
    try {
      final response = await _dio.post(
        'check_tv_login',
        data: {
          'unique_code': uniqueCode,
          'device_name': 'Android TV',
          'device_id': Constant.deviceId,
          'device_type': 3, // 3 = TV
        },
      );
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        if (data['status'] == 200 && data['result'] != null) {
          final res = data['result'];
          if (res is List && res.isNotEmpty) {
            return TVUserData.fromJson(res[0]);
          } else if (res is Map<String, dynamic>) {
            return TVUserData.fromJson(res);
          }
        }
      }
    } catch (e) {
      debugPrint("Error checkTvLogin: $e");
    }
    return null;
  }
}
