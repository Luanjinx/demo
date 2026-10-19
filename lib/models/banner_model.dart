class BannerListModel {
  int? status;
  String? message;
  List<BannerItem>? result;

  BannerListModel({this.status, this.message, this.result});

  factory BannerListModel.fromJson(Map<String, dynamic> json) {
    return BannerListModel(
      status: json['status'],
      message: json['message'],
      result: json['result'] != null
          ? (json['result'] as List).map((i) => BannerItem.fromJson(i)).toList()
          : null,
    );
  }
}

class BannerItem {
  int? id;
  String? name;
  String? thumbnail;
  String? landscape;
  String? description;
  int? videoType;
  int? subVideoType;
  int? typeId;
  String? categoryName;
  int? isPremium;
  int? isBuy;

  BannerItem({
    this.id,
    this.name,
    this.thumbnail,
    this.landscape,
    this.description,
    this.videoType,
    this.subVideoType,
    this.typeId,
    this.categoryName,
    this.isPremium,
    this.isBuy,
  });

  String get bannerImage {
    if (landscape != null && landscape!.isNotEmpty && !landscape!.contains('no_img')) {
      return landscape!;
    }
    return thumbnail ?? '';
  }

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: json['id'],
      name: json['name'],
      thumbnail: json['thumbnail'],
      landscape: json['landscape'],
      description: json['description'],
      videoType: json['video_type'],
      subVideoType: json['sub_video_type'],
      typeId: json['type_id'],
      categoryName: json['category_name'],
      isPremium: json['is_premium'],
      isBuy: json['is_buy'],
    );
  }
}
