// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_scan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingScanAdapter extends TypeAdapter<PendingScan> {
  @override
  final int typeId = 0;

  @override
  PendingScan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingScan(
      imagePath: fields[0] as String,
      capturedAt: fields[1] as DateTime,
      isSyncing: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PendingScan obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.imagePath)
      ..writeByte(1)
      ..write(obj.capturedAt)
      ..writeByte(2)
      ..write(obj.isSyncing);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingScanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
