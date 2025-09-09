// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_metadata.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StoryMetadataAdapter extends TypeAdapter<StoryMetadata> {
  @override
  final int typeId = 2;

  @override
  StoryMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StoryMetadata(
      storyId: fields[0] as String,
      currentTurn: fields[1] as int,
      lastPlayedAt: fields[2] as DateTime?,
      isCompleted: fields[3] as bool,
      totalTokensSpent: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, StoryMetadata obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.storyId)
      ..writeByte(1)
      ..write(obj.currentTurn)
      ..writeByte(2)
      ..write(obj.lastPlayedAt)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.totalTokensSpent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
