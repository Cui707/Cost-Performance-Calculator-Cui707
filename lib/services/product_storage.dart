// lib/services/product_storage.dart

import 'dart:convert'; // 用于 JSON 编解码

import 'package:costperformanceclaculatorcui707/models/product.dart'; // 导入 Product 模型
import 'package:shared_preferences/shared_preferences.dart'; // 导入 SharedPreferences

class ProductStorage {
  static const String _productsKey = 'products_key'; // 产品列表的存储键
  static const String _categoriesKey = 'categories_key'; // 分类列表的存储键

  // 保存产品列表
  Future<void> saveProducts(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    // 将 List<Product> 转换为 List<Map<String, dynamic>>
    final List<Map<String, dynamic>> jsonList =
        products.map((product) => product.toJson()).toList();
    // 将 List<Map<String, dynamic>> 编码为 JSON 字符串
    await prefs.setString(_productsKey, jsonEncode(jsonList));
  }

  // 加载产品列表
  Future<List<Product>> loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? productsString = prefs.getString(_productsKey);

    if (productsString == null) {
      return []; // 如果没有存储数据，返回空列表
    }

    // 将 JSON 字符串解码为 List<dynamic>
    final List<dynamic> jsonList = jsonDecode(productsString);
    // 将 List<dynamic> 映射回 List<Product>
    return jsonList.map((json) => Product.fromJson(json)).toList();
  }

  // 保存分类列表
  Future<void> saveCategories(List<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_categoriesKey, categories);
  }

  // 加载分类列表
  Future<List<String>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? categories = prefs.getStringList(_categoriesKey);
    // 如果没有存储数据，返回包含默认分类的列表，确保总有一个分类
    return categories ?? ['未分类'];
  }
}