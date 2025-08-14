// models/chore.dart

import 'dart:convert'; // Required for JSON encoding/decoding

// A data model for a single chore with JSON serialization methods
class Chore {
  final String day;
  final String title;
  final double price;
  bool isCompletedByChild;
  bool isApprovedByParent;

  Chore({
    required this.day,
    required this.title,
    required this.price,
    this.isCompletedByChild = false,
    this.isApprovedByParent = false,
  });

  // Convert a Chore object into a Map (JSON-like format)
  Map<String, dynamic> toJson() => {
        'day': day,
        'title': title,
        'price': price,
        'isCompletedByChild': isCompletedByChild,
        'isApprovedByParent': isApprovedByParent,
      };

  // Create a Chore object from a Map (JSON-like format)
  factory Chore.fromJson(Map<String, dynamic> json) {
    return Chore(
      day: json['day'] as String,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      isCompletedByChild: json['isCompletedByChild'] as bool,
      isApprovedByParent: json['isApprovedByParent'] as bool,
    );
  }
}
