  class UserModel {
    String? status;
    String? msg;
    List<User>? data;

    UserModel({this.status, this.msg, this.data});

    UserModel.fromJson(Map<String, dynamic> json) {
      status = json['status'];
      msg = json['msg'];
      if (json['data'] != null) {
        data = <User>[];
        json['data'].forEach((v) {
          data!.add(new User.fromJson(v));
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

  class User {
    int? id;
    String? name;
    String? email;
    String? phone;
    String? password;
    String? locationLat;
    String? locationLong;
    String? createdAt;
    String? updatedAt;

    User(
        {this.id,
        this.name,
        this.email,
        this.phone,
        this.password,
        this.locationLat,
        this.locationLong,
        this.createdAt,
        this.updatedAt});

    User.fromJson(Map<String, dynamic> json) {
      id = json['id'];
      name = json['name'];
      email = json['email'];
      phone = json['phone'];
      password = json['password'];
      locationLat = json['location_lat'].toString() != 'null'
          ? json['location_lat'].toString()
          : null;
      locationLong = json['location_long'].toString() != 'null'
          ? json['location_long'].toString()
          : null;
      createdAt = json['createdAt'];
      updatedAt = json['updatedAt'];
    }

    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = new Map<String, dynamic>();
      data['id'] = this.id;
      data['name'] = this.name;
      data['email'] = this.email;
      data['phone'] = this.phone;
      data['password'] = this.password;
      data['location_lat'] = this.locationLat;
      data['location_long'] = this.locationLong;
      data['createdAt'] = this.createdAt;
      data['updatedAt'] = this.updatedAt;
      return data;
    }
  }