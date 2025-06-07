// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favoritePetModel.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FavoritePetAdapter extends TypeAdapter<FavoritePet> {
  @override
  final int typeId = 0;

  @override
  FavoritePet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FavoritePet(
      petId: fields[0] as String,
      userEmail: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FavoritePet obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.petId)
      ..writeByte(1)
      ..write(obj.userEmail);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoritePetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
