// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playthrough_metadata.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlaythroughMetadataAdapter extends TypeAdapter<PlaythroughMetadata> {
  @override
  final int typeId = 3;

  @override
  PlaythroughMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlaythroughMetadata(
      storyId: fields[0] as String,
      playthroughId: fields[1] as String,
      saveName: fields[2] as String,
      createdAt: fields[3] as DateTime,
      lastPlayedAt: fields[4] as DateTime,
      currentTurn: fields[5] as int,
      totalTurns: fields[6] as int,
      status: fields[7] as String,
      lastUserInput: fields[8] as String?,
      lastInputTime: fields[9] as DateTime?,
      statusMessage: fields[10] as String?,
      tokensSpent: fields[11] as int,
      isCompleted: fields[12] as bool,
      endingDescription: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PlaythroughMetadata obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.storyId)
      ..writeByte(1)
      ..write(obj.playthroughId)
      ..writeByte(2)
      ..write(obj.saveName)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.lastPlayedAt)
      ..writeByte(5)
      ..write(obj.currentTurn)
      ..writeByte(6)
      ..write(obj.totalTurns)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.lastUserInput)
      ..writeByte(9)
      ..write(obj.lastInputTime)
      ..writeByte(10)
      ..write(obj.statusMessage)
      ..writeByte(11)
      ..write(obj.tokensSpent)
      ..writeByte(12)
      ..write(obj.isCompleted)
      ..writeByte(13)
      ..write(obj.endingDescription);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaythroughMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
