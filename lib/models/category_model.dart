import 'package:flutter/material.dart'; // For IconData

class CategoryModel {
  final String id;
  final String name;
  final String? imageUrl; // Optional image for category
  final IconData? icon; // Optional icon for category

  CategoryModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.icon,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
      // You might map a string from the API to an IconData here if needed
      // For now, we'll leave it null or provide a default
      icon: _getIconData(json['icon_name'] as String?),
    );
  }

  static IconData? _getIconData(String? iconName) {
    if (iconName == null) return null;
    // This is a simplified mapping. In a real app, you'd have a comprehensive map
    // or use a custom icon font.
    switch (iconName.toLowerCase()) {
      case 'medication_liquid':
        return Icons.medication_liquid;
      case 'healing':
        return Icons.healing;
      case 'medication':
        return Icons.medication;
      case 'shower':
        return Icons.shower;
      case 'child_care':
        return Icons.child_care;
      case 'medical_services':
        return Icons.medical_services;
      case 'biotech':
        return Icons.biotech;
      case 'grass':
        return Icons.grass;
      case 'monitor_heart':
        return Icons.monitor_heart;
      case 'pets':
        return Icons.pets;
      default:
        return Icons.category; // Default icon
    }
  }
}
