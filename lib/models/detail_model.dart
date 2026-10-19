import 'section_model.dart';

class ContentDetailModel {
  int? status;
  String? message;
  DetailResult? result;

  ContentDetailModel({this.status, this.message, this.result});

  factory ContentDetailModel.fromJson(Map<String, dynamic> json) {
    dynamic res = json['result'];
    DetailResult? detail;
    if (res is List && res.isNotEmpty) {
      detail = DetailResult.fromJson(res[0]);
    } else if (res is Map<String, dynamic>) {
      detail = DetailResult.fromJson(res);
    }
    return ContentDetailModel(
      status: json['status'],
      message: json['message'],
      result: detail,
    );
  }
}

class DetailResult {
  int? id;
  String? name;
  String? title;
  String? thumbnail;
  String? landscape;
  String? description;
  int? totalView;
  int? totalLike;
  dynamic avgRating;
  int? isPremium;
  int? isBuy;
  int? isBookmark;
  int? videoType;
  int? subVideoType;
  int? typeId;
  String? releaseYear;
  String? releaseDate;
  String? categoryName;
  String? duration;
  String? videoUrl;
  String? video320;
  String? video480;
  String? video720;
  String? video1080;
  String? videoUploadType;
  List<SeasonItem>? seasons;
  List<EpisodeItem>? episodes;
  List<ContentItem>? relatedContent;

  DetailResult({
    this.id,
    this.name,
    this.title,
    this.thumbnail,
    this.landscape,
    this.description,
    this.totalView,
    this.totalLike,
    this.avgRating,
    this.isPremium,
    this.isBuy,
    this.isBookmark,
    this.videoType,
    this.subVideoType,
    this.typeId,
    this.releaseYear,
    this.releaseDate,
    this.categoryName,
    this.duration,
    this.videoUrl,
    this.video320,
    this.video480,
    this.video720,
    this.video1080,
    this.videoUploadType,
    this.seasons,
    this.episodes,
    this.relatedContent,
  });

  String get displayName => (name != null && name!.isNotEmpty) ? name! : (title ?? '');

  String get backdropImage {
    if (landscape != null && landscape!.isNotEmpty && !landscape!.contains('no_img')) {
      return landscape!;
    }
    return thumbnail ?? '';
  }

  String get posterImage {
    if (thumbnail != null && thumbnail!.isNotEmpty && !thumbnail!.contains('no_img')) {
      return thumbnail!;
    }
    return landscape ?? '';
  }

  factory DetailResult.fromJson(Map<String, dynamic> json) {
    return DetailResult(
      id: json['id'],
      name: json['name'],
      title: json['title'],
      thumbnail: json['thumbnail'],
      landscape: json['landscape'],
      description: json['description'],
      totalView: json['total_view'] is int ? json['total_view'] : int.tryParse(json['total_view']?.toString() ?? '0'),
      totalLike: json['total_like'] is int ? json['total_like'] : int.tryParse(json['total_like']?.toString() ?? '0'),
      avgRating: json['avg_rating'],
      isPremium: json['is_premium'],
      isBuy: json['is_buy'],
      isBookmark: json['is_bookmark'] ?? 0,
      videoType: json['video_type'],
      subVideoType: json['sub_video_type'],
      typeId: json['type_id'],
      releaseYear: json['release_year']?.toString(),
      releaseDate: json['release_date']?.toString(),
      categoryName: json['category_name']?.toString(),
      duration: json['duration']?.toString(),
      videoUrl: json['video_url'] ?? json['video_320'],
      video320: json['video_320'],
      video480: json['video_480'],
      video720: json['video_720'],
      video1080: json['video_1080'],
      videoUploadType: json['video_upload_type'],
      seasons: json['session'] != null
          ? (json['session'] as List).map((i) => SeasonItem.fromJson(i)).toList()
          : null,
      episodes: json['episode'] != null
          ? (json['episode'] as List).map((i) => EpisodeItem.fromJson(i)).toList()
          : null,
      relatedContent: json['related_video'] != null
          ? (json['related_video'] as List).map((i) => ContentItem.fromJson(i)).toList()
          : null,
    );
  }
}

class SeasonItem {
  int? id;
  String? name;
  int? showId;

  SeasonItem({this.id, this.name, this.showId});

  factory SeasonItem.fromJson(Map<String, dynamic> json) {
    return SeasonItem(
      id: json['id'],
      name: json['name'],
      showId: json['show_id'],
    );
  }
}

class EpisodeItem {
  int? id;
  int? showId;
  int? seasonId;
  String? name;
  String? thumbnail;
  String? landscape;
  String? description;
  String? videoUrl;
  String? video320;
  String? video480;
  String? video720;
  String? video1080;
  String? videoUploadType;
  int? isPremium;
  int? isBuy;

  EpisodeItem({
    this.id,
    this.showId,
    this.seasonId,
    this.name,
    this.thumbnail,
    this.landscape,
    this.description,
    this.videoUrl,
    this.video320,
    this.video480,
    this.video720,
    this.video1080,
    this.videoUploadType,
    this.isPremium,
    this.isBuy,
  });

  factory EpisodeItem.fromJson(Map<String, dynamic> json) {
    return EpisodeItem(
      id: json['id'],
      showId: json['show_id'],
      seasonId: json['session_id'] ?? json['season_id'],
      name: json['name'],
      thumbnail: json['thumbnail'],
      landscape: json['landscape'],
      description: json['description'],
      videoUrl: json['video_url'] ?? json['video_320'],
      video320: json['video_320'],
      video480: json['video_480'],
      video720: json['video_720'],
      video1080: json['video_1080'],
      videoUploadType: json['video_upload_type'],
      isPremium: json['is_premium'],
      isBuy: json['is_buy'],
    );
  }
}
