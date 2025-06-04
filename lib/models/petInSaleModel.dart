class PetInSaleModel {
  String? status;
  String? msg;
  List<PetInSale>? data;

  PetInSaleModel({this.status, this.msg, this.data});

  PetInSaleModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    msg = json['msg'];
    if (json['data'] != null) {
      data = <PetInSale>[];
      json['data'].forEach((v) {
        data!.add(new PetInSale.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['msg'] = this.msg;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class PetInSale {
  int? id;
  String? name;
  String? category;
  String? description;
  double? price;
  int? age;
  String? healthStatus;
  String? imgUrl;
  double? locationLat;
  double? locationLong;
  String? email;
  String? status;

  PetInSale(
      {this.id,
      this.name,
      this.category,
      this.description,
      this.price,
      this.age,
      this.healthStatus,
      this.imgUrl,
      this.locationLat,
      this.locationLong,
      this.email,
      this.status});

  PetInSale.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    category = json['category'];
    description = json['description'];
    price = json['price'].toString() != 'null'
            ? double.parse(json['price'].toString())
            : null;
    age = json['age'];
    healthStatus = json['healthStatus'];
    imgUrl = json['imgUrl'];
    locationLat = json['location_lat'].toString() != 'null'
            ? double.parse(json['location_lat'].toString())
            : null;
    locationLong = json['location_long'].toString() != 'null'
            ? double.parse(json['location_long'].toString())
            : null;
    email = json['email'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['category'] = this.category;
    data['description'] = this.description;
    data['price'] = this.price;
    data['age'] = this.age;
    data['healthStatus'] = this.healthStatus;
    data['imgUrl'] = this.imgUrl;
    data['location_lat'] = this.locationLat;
    data['location_long'] = this.locationLong;
    data['email'] = this.email;
    data['status'] = this.status;
    return data;
  }
}