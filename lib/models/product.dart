// lib/models/product.dart

import 'package:uuid/uuid.dart';

class Product {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final double totalPrice;
  final String category;
  final String? notes;
  final String? imagePath;

  Product({
    String? id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.totalPrice,
    required this.category,
    this.notes,
    this.imagePath,
  }) : id = id ?? const Uuid().v4();

  // 计算每单位价格
  // 还原到直接使用 quantity，不进行自动转换
  double get pricePerUnit {
    return totalPrice / quantity;
  }

  // 将Product对象转换为JSON格式
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'totalPrice': totalPrice,
        'category': category,
        'notes': notes,
        'imagePath': imagePath,
      };

  // 从JSON格式创建Product对象
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'] as double,
      unit: json['unit'] as String,
      totalPrice: json['totalPrice'] as double,
      category: json['category'] as String,
      notes: json['notes'] as String?,
      imagePath: json['imagePath'] as String?,
    );
  }

  // 用于调试的toString方法
  @override
  String toString() {
    return 'Product(id: $id, name: $name, quantity: $quantity, unit: $unit, totalPrice: $totalPrice, category: $category, notes: $notes, imagePath: $imagePath)';
  }
}