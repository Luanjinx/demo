class TVLoginCodeModel {
  int? status;
  String? message;
  List<TVCodeResult>? result;

  TVLoginCodeModel({this.status, this.message, this.result});

  factory TVLoginCodeModel.fromJson(Map<String, dynamic> json) {
    return TVLoginCodeModel(
      status: json['status'],
      message: json['message'],
      result: json['result'] != null
          ? (json['result'] as List).map((i) => TVCodeResult.fromJson(i)).toList()
          : null,
    );
  }
}

class TVCodeResult {
  int? id;
  String? uniqueCode;
  int? userId;
  int? status;

  TVCodeResult({this.id, this.uniqueCode, this.userId, this.status});

  factory TVCodeResult.fromJson(Map<String, dynamic> json) {
    return TVCodeResult(
      id: json['id'],
      uniqueCode: json['unique_code']?.toString(),
      userId: json['user_id'],
      status: json['status'],
    );
  }
}

class TVUserData {
  int? id;
  String? name;
  String? email;
  String? mobile;
  String? image;
  int? isBuy;

  TVUserData({this.id, this.name, this.email, this.mobile, this.image, this.isBuy});

  factory TVUserData.fromJson(Map<String, dynamic> json) {
    return TVUserData(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      mobile: json['mobile'],
      image: json['image'],
      isBuy: json['is_buy'],
    );
  }
}
