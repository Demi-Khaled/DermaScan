import 'package:hive/hive.dart';
import 'lesion.dart';
import 'risk_level.dart';

class RiskLevelAdapter extends TypeAdapter<RiskLevel> {
  @override
  final int typeId = 1;

  @override
  RiskLevel read(BinaryReader reader) {
    return RiskLevel.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, RiskLevel obj) {
    writer.writeByte(obj.index);
  }
}

class ScanEntryAdapter extends TypeAdapter<ScanEntry> {
  @override
  final int typeId = 2;

  @override
  ScanEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScanEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      riskLevel: fields[2] as RiskLevel,
      confidence: fields[3] as double,
      imagePath: fields[4] as String?,
      explanation: fields[5] as String,
      recommendation: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ScanEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.date)
      ..writeByte(2)..write(obj.riskLevel)
      ..writeByte(3)..write(obj.confidence)
      ..writeByte(4)..write(obj.imagePath)
      ..writeByte(5)..write(obj.explanation)
      ..writeByte(6)..write(obj.recommendation);
  }
}

class LesionAdapter extends TypeAdapter<Lesion> {
  @override
  final int typeId = 3;

  @override
  Lesion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Lesion(
      id: fields[0] as String,
      name: fields[1] as String,
      bodyLocation: fields[2] as String,
      latestRisk: fields[3] as RiskLevel,
      firstDetected: fields[4] as DateTime,
      lastScan: fields[5] as DateTime,
      notes: fields[6] as String,
      imagePath: fields[7] as String?,
      scanHistory: (fields[8] as List).cast<ScanEntry>(),
      reminderDate: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Lesion obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.bodyLocation)
      ..writeByte(3)..write(obj.latestRisk)
      ..writeByte(4)..write(obj.firstDetected)
      ..writeByte(5)..write(obj.lastScan)
      ..writeByte(6)..write(obj.notes)
      ..writeByte(7)..write(obj.imagePath)
      ..writeByte(8)..write(obj.scanHistory)
      ..writeByte(9)..write(obj.reminderDate);
  }
}
