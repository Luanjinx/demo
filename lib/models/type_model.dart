class TypeListModel {
  int? status;
  String? message;
  List<TypeItem>? result;

  TypeListModel({this.status, this.message, this.result});

  factory TypeListModel.fromJson(Map<String, dynamic> json) {
    return TypeListModel(
      status: json['status'],
      message: json['message'],
      result: json['result'] != null
          ? (json['result'] as List).map((i) => TypeItem.fromJson(i)).toList()
          : null,
    );
  }
}

class TypeItem {
  int? id;
  String? name;
  int? type;

  TypeItem({this.id, this.name, this.type});

  factory TypeItem.fromJson(Map<String, dynamic> json) {
    return TypeItem(
      id: json['id'],
      name: json['name'],
      type: json['type'],
    );
  }
}
