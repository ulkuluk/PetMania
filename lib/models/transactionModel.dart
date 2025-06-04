class TransactionModel {
  String? status;
  String? msg;
  List<Transaction>? data;

  TransactionModel({this.status, this.msg, this.data});

  TransactionModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    msg = json['msg'];
    if (json['data'] != null) {
      data = <Transaction>[];
      json['data'].forEach((v) {
        data!.add(new Transaction.fromJson(v));
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

class Transaction {
  int? id;
  String? buyerEmail;
  int? animalId;
  String? sellerEmail;
  String? status;
  double? price;
  String? shippingAddress;
  String? createdAt;
  String? updatedAt;

  Transaction(
      {this.id,
      this.buyerEmail,
      this.animalId,
      this.sellerEmail,
      this.status,
      this.price,
      this.shippingAddress,
      this.createdAt,
      this.updatedAt});

  Transaction.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    buyerEmail = json['buyerEmail'];
    animalId = json['animalId'];
    sellerEmail = json['sellerEmail'];
    status = json['status'];
    price = json['price'].toString() != 'null'
            ? double.parse(json['price'].toString())
            : null;
    shippingAddress = json['shipping_address'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['buyerEmail'] = this.buyerEmail;
    data['animalId'] = this.animalId;
    data['sellerEmail'] = this.sellerEmail;
    data['status'] = this.status;
    data['price'] = this.price;
    data['shipping_address'] = this.shippingAddress;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}