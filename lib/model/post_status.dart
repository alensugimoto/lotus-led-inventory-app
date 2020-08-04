import 'package:json_annotation/json_annotation.dart';

part 'post_status.g.dart';

@JsonSerializable()
class PostStatus {
  bool successful;
  List<String> sheetNames;

  PostStatus(this.successful, this.sheetNames);

  factory PostStatus.fromJson(Map<String, dynamic> json) => _$PostStatusFromJson(json);

  Map<String, dynamic> toJson() => _$PostStatusToJson(this);
}
