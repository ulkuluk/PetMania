import 'package:hive/hive.dart';

part 'favoritePetModel.g.dart'; 

@HiveType(typeId: 0) 
class FavoritePet extends HiveObject {
  @HiveField(0)
  final String petId;
  @HiveField(1)
  final String userEmail;

  FavoritePet({required this.petId, required this.userEmail});
}
