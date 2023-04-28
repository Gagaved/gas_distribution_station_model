
import 'package:flutter/material.dart';

class GdsElementType {
  final int id;
  final String type;

  GdsElementType(this.id, this.type,);

  GdsElementType.fromJson(Map<String, dynamic> json)
      :
        id = json['id'],
        type = json['type'];
}