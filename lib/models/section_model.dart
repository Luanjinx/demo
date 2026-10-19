class SectionListModel {
  int? status;
  String? message;
  List<SectionItem>? result;

  SectionListModel({this.status, this.message, this.result});

  factory SectionListModel.fromJson(Map<String, dynamic> json) {
    return SectionListModel(
      status: json['status'],
      message: json['message'],
      result: json['result'] != null
          ? (json['result'] as List).map((i) => SectionItem.fromJson(i)).toList()
          : null,
    );
  }
}

class SectionItem {
  int? id;
  int? isHomeScreen;
  int? typeId;
  int? videoType;
  int? subVideoType;
  String? screenLayout;
  String? title;
  String? shortTitle;
  int? viewAll;
  List<ContentItem>? data;

  SectionItem({
    this.id,
    this.isHomeScreen,
    this.typeId,
    this.videoType,
    this.subVideoType,
    this.screenLayout,
    this.title,
    this.shortTitle,
    this.viewAll,
    this.data,
  });

  factory SectionItem.fromJson(Map<String, dynamic> json) {
    return SectionItem(
      id: json['id'],
      isHomeScreen: json['is_home_screen'],
      typeId: json['type_id'],
      videoType: json['video_type'],
      subVideoType: json['sub_video_type'],
      screenLayout: json['screen_layout'] ?? 'portrait',
      title: json['title'] ?? '',
      shortTitle: json['short_title'] ?? '',
      viewAll: json['view_all'],
      data: json['data'] != null
          ? (json['data'] as List).map((i) => ContentItem.fromJson(i)).toList()
          : null,
    );
  }
}

class ContentItem {
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
  int? videoType;
  int? subVideoType;
  int? typeId;
  String? releaseYear;
  String? releaseDate;
  String? categoryName;
  String? duration;
  String? videoUrl;
  String? videoUploadType;

  ContentItem({
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
    this.videoType,
    this.subVideoType,
    this.typeId,
    this.releaseYear,
    this.releaseDate,
    this.categoryName,
    this.duration,
    this.videoUrl,
    this.videoUploadType,
  });

  String get displayName => (name != null && name!.isNotEmpty) ? name! : (title ?? '');

  String get posterImage {
    if (thumbnail != null && thumbnail!.isNotEmpty && !thumbnail!.contains('no_img')) {
      return thumbnail!;
    }
    return landscape ?? '';
  }

  String get backdropImage {
    if (landscape != null && landscape!.isNotEmpty && !landscape!.contains('no_img')) {
      return landscape!;
    }
    return thumbnail ?? '';
  }

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
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
      videoType: json['video_type'],
      subVideoType: json['sub_video_type'],
      typeId: json['type_id'],
      releaseYear: json['release_year']?.toString(),
      releaseDate: json['release_date']?.toString(),
      categoryName: json['category_name']?.toString(),
      duration: json['duration']?.toString(),
      videoUrl: json['video_320'] ?? json['video_url'] ?? json['video_upload_type'],
      videoUploadType: json['video_upload_type'],
    );
  }
}
