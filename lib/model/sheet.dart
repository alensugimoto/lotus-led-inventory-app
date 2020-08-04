import 'package:json_annotation/json_annotation.dart';

part 'sheet.g.dart';

@JsonSerializable()
class Sheet {
  List<Map<String, String>> lights;
  List<String> headers, members;

  Sheet(this.lights, this.headers, this.members);

  factory Sheet.fromJson(Map<String, dynamic> json) => _$SheetFromJson(json);

  Map<String, dynamic> toJson() => _$SheetToJson(this);
}
