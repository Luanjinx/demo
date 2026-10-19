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
        validateStatus: (status) => true, // Don't throw DioException on 400 status codes
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

  int get _numericUserId => int.tryParse(Constant.userId ?? '0') ?? 0;

  // 1. Fetch Types (Movies, Series, Anime, etc.)
  Future<TypeListModel> getTypes() async {
    try {
      final response = await _dio.post(
        'get_type',
        data: {
          'user_id': _numericUserId,
          'device_id': Constant.deviceId,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        if (data != null && data['status'] == 200) {
          return TypeListModel.fromJson(data);
        }
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
          'user_id': _numericUserId,
          'type_id': typeId,
          'is_home_screen': isHomeScreen,
          'device_id': Constant.deviceId,
          'is_kids_profile': 0,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        if (data != null && data['status'] == 200) {
          return BannerListModel.fromJson(data);
        }
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
          'user_id': _numericUserId,
          'type_id': typeId,
          'is_home_screen': isHomeScreen,
          'device_id': Constant.deviceId,
          'is_kids_profile': 0,
          'page_no': pageNo,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        if (data != null && data['status'] == 200) {
          return SectionListModel.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint("Error getSections: $e");
    }
    return SectionListModel(status: 400, result: []);
  }

  // 4. Fetch Details ('content_detail') with resilient fallback
  Future<ContentDetailModel> getContentDetail({
    required int id,
    required int videoType,
    int typeId = 0,
    int subVideoType = 0,
  }) async {
    // 1. If typeId is given (> 0), try it first with requested videoType
    if (typeId > 0) {
      final res = await _requestContentDetail(
        id: id,
        videoType: videoType,
        typeId: typeId,
        subVideoType: subVideoType,
      );
      if (res.status == 200 && res.result != null) return res;
    }

    // 2. Candidate type IDs prioritized by videoType
    final List<int> candidates = [];
    if (videoType == Constant.videoTypeMovie) {
      candidates.addAll([10, 2, 11, 7, 6, 3]);
    } else if (videoType == Constant.videoTypeTVShow) {
      candidates.addAll([11, 2, 10, 7, 6, 3]);
    } else if (videoType == Constant.videoTypeShorts) {
      candidates.addAll([7, 2, 10, 11]);
    } else {
      candidates.addAll([11, 2, 10, 7, 6, 3]);
    }

    for (final t in candidates) {
      if (t == typeId) continue;
      final res = await _requestContentDetail(
        id: id,
        videoType: videoType,
        typeId: t,
        subVideoType: subVideoType,
      );
      if (res.status == 200 && res.result != null) return res;
    }

    // 3. Fallback alternative videoTypes (e.g., if videoType was guessed incorrectly)
    final altVideoTypes = [Constant.videoTypeTVShow, Constant.videoTypeMovie, Constant.videoTypeShorts]
        .where((vt) => vt != videoType)
        .toList();

    for (final vt in altVideoTypes) {
      final altCandidates = (vt == Constant.videoTypeMovie)
          ? [10, 2, 11, 7]
          : (vt == Constant.videoTypeTVShow ? [11, 2, 10, 7] : [7, 2, 10, 11]);
      for (final t in altCandidates) {
        final res = await _requestContentDetail(
          id: id,
          videoType: vt,
          typeId: t,
          subVideoType: subVideoType,
        );
        if (res.status == 200 && res.result != null) return res;
      }
    }

    return ContentDetailModel(status: 400, result: null);
  }

  Future<ContentDetailModel> _requestContentDetail({
    required int id,
    required int videoType,
    required int typeId,
    int subVideoType = 0,
  }) async {
    try {
      final response = await _dio.post(
        'content_detail',
        data: {
          'type_id': typeId,
          'video_type': videoType,
          'video_id': id,
          'sub_video_type': subVideoType,
          'user_id': _numericUserId,
          'device_id': Constant.deviceId,
          'is_kids_profile': 0,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        if (data != null && data['status'] == 200 && data['result'] != null) {
          return ContentDetailModel.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint("Error requestContentDetail: $e");
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
          'user_id': _numericUserId,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        if (data != null && data['status'] == 200 && data['result'] != null && data['result'] is List) {
          return (data['result'] as List).map((i) => EpisodeItem.fromJson(i)).toList();
        }
      }
    } catch (e) {
      debugPrint("Error getEpisodesBySeason: $e");
    }
    return [];
  }

  // 5b. Fetch Shorts Episodes ('get_shorts_episode')
  Future<List<EpisodeItem>> getShortsEpisodes({
    required int shortsId,
    int seasonId = 0,
  }) async {
    try {
      final response = await _dio.post(
        'get_shorts_episode',
        data: {
          'shorts_id': shortsId,
          'season_id': seasonId,
          'user_id': _numericUserId,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        if (data != null && data['status'] == 200 && data['result'] != null && data['result'] is List) {
          return (data['result'] as List).map((i) => EpisodeItem.fromJson(i)).toList();
        }
      }
    } catch (e) {
      debugPrint("Error getShortsEpisodes: $e");
    }
    return [];
  }

  // 6. Fetch Related Content ('get_releted_content')
  Future<List<ContentItem>> getRelatedContent({
    required int id,
    required int videoType,
    required int typeId,
    int subVideoType = 0,
    int pageNo = 1,
  }) async {
    try {
      final response = await _dio.post(
        'get_releted_content',
        data: {
          'type_id': typeId,
          'video_type': videoType,
          'video_id': id,
          'sub_video_type': subVideoType,
          'user_id': _numericUserId,
          'device_id': Constant.deviceId,
          'is_kids_profile': 0,
          'page_no': pageNo,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        if (data != null && data['status'] == 200 && data['result'] != null && data['result'] is List) {
          return (data['result'] as List).map((i) => ContentItem.fromJson(i)).toList();
        }
      }
    } catch (e) {
      debugPrint("Error getRelatedContent: $e");
    }
    return [];
  }

  // 7. Search Content ('search_content')
  Future<List<ContentItem>> search({required String query}) async {
    try {
      final response = await _dio.post(
        'search_content',
        data: {
          'title': query,
          'user_id': _numericUserId,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        if (data != null && data['result'] != null && data['result'] is List) {
          return (data['result'] as List).map((i) => ContentItem.fromJson(i)).toList();
        }
      }
    } catch (e) {
      debugPrint("Error search: $e");
    }
    return [];
  }

  // 8. TV Activation Login (Generate Code: 'get_tv_login_code')
  Future<TVLoginCodeModel> getTvLoginCode() async {
    try {
      final response = await _dio.post('get_tv_login_code', data: {});
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        if (data != null && data['status'] == 200) {
          return TVLoginCodeModel.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint("Error getTvLoginCode: $e");
    }
    return TVLoginCodeModel(status: 400, result: []);
  }

  // 9. TV Activation Login (Poll Status: 'check_tv_login')
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
        if (data != null && data['status'] == 200 && data['result'] != null) {
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
