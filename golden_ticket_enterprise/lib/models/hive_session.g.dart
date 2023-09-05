// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveSessionAdapter extends TypeAdapter<HiveSession> {
  @override
  final int typeId = 2;

  @override
  HiveSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveSession(
      user: fields[0] as User,
      sessionExpiryAt: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HiveSession obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.user)
      ..writeByte(1)
      ..write(obj.sessionExpiryAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
