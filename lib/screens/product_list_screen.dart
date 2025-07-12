// lib/screens/product_list_screen.dart

import 'package:flutter/material.dart';
import 'package:costperformanceclaculatorcui707/models/product.dart';
import 'package:costperformanceclaculatorcui707/services/product_storage.dart';
import 'package:costperformanceclaculatorcui707/screens/add_edit_product_screen.dart';
import 'package:costperformanceclaculatorcui707/screens/category_product_list_screen.dart'; 
import 'dart:io';

// 假设 Product 和 ProductStorage 类在这里或其他文件已定义

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductStorage _productStorage = ProductStorage();
  List<Product> _products = [];
  List<String> _categories = [];
  // _currentCategory 在这个屏幕上不再用于直接过滤显示产品，
  // 而是作为 AddEditProductScreen 的默认分类传入，或者旧代码的遗留
  String _currentCategory = '未分类'; 
  
  TextEditingController _searchController = TextEditingController(); // 用于分类搜索的控制器
  List<String> _filteredCategories = []; // 过滤后的分类列表，用于显示

  @override
  void initState() {
    super.initState();
    _loadData();
    // 监听搜索框文本变化，实时过滤分类
    _searchController.addListener(_filterCategories); 
  }

  @override
  void dispose() {
    _searchController.dispose(); // 释放控制器资源
    super.dispose();
  }

  // 加载产品和分类数据
  Future<void> _loadData() async {
    final loadedProducts = await _productStorage.loadProducts();
    final loadedCategories = await _productStorage.loadCategories();
    setState(() {
      _products = loadedProducts;
      _categories = loadedCategories;
      // 确保 '未分类' 始终存在于分类列表中
      if (!_categories.contains('未分类')) {
        _categories.insert(0, '未分类'); 
      }
      // 初始化 _filteredCategories 为所有分类
      _filteredCategories = List<String>.from(_categories); 
      // _currentCategory 在此页面不再用于产品筛选，但保留以防其他地方仍引用
      _currentCategory = _categories.isNotEmpty ? _categories.first : '未分类';
    });
  }

  // 保存产品数据
  Future<void> _saveProducts() async {
    await _productStorage.saveProducts(_products);
  }

  // 保存分类数据
  Future<void> _saveCategories() async {
    await _productStorage.saveCategories(_categories);
  }

  // 根据搜索框内容过滤分类
  void _filterCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCategories = _categories
          .where((category) => category.toLowerCase().contains(query))
          .toList();
    });
  }

  // 添加新分类的对话框
  void _showAddCategoryDialog() {
    String newCategoryName = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('添加新分类'),
          content: TextField(
            autofocus: true,
            onChanged: (value) {
              newCategoryName = value;
            },
            decoration: const InputDecoration(hintText: '输入分类名称'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.black),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.black,
              ),
              child: const Text('添加'),
              onPressed: () {
                if (newCategoryName.isNotEmpty && !_categories.contains(newCategoryName)) {
                  setState(() {
                    _categories.add(newCategoryName);
                    // 添加新分类后也要更新过滤后的列表，否则搜索框需要清空或输入才能显示新分类
                    _filterCategories(); 
                  });
                  _saveCategories();
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 编辑分类的对话框
void _showEditCategoryDialog(String oldCategoryName) {
  String newCategoryName = oldCategoryName;
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('编辑分类'),
        content: TextField(
          autofocus: true,
          controller: TextEditingController(text: oldCategoryName),
          onChanged: (value) {
            newCategoryName = value;
          },
          decoration: const InputDecoration(hintText: '输入新分类名称'),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('取消'),
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.black),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
            child: const Text('保存'),
            onPressed: () {
              if (newCategoryName.isNotEmpty && newCategoryName != oldCategoryName && !_categories.contains(newCategoryName)) {
                setState(() {
                  final index = _categories.indexOf(oldCategoryName);
                  if (index != -1) {
                    _categories[index] = newCategoryName;
                    // --- 修改从这里开始 ---
                    // 创建一个临时列表来存放更新后的产品，因为不能直接修改_products迭代
                    List<Product> updatedProducts = [];
                    for (var product in _products) {
                      if (product.category == oldCategoryName) {
                        // 创建一个新的 Product 实例，并更新其 category 属性
                        updatedProducts.add(
                          Product(
                            id: product.id,
                            name: product.name,
                            quantity: product.quantity,
                            unit: product.unit,
                            totalPrice: product.totalPrice,
                            category: newCategoryName, // 这里是更新分类
                            notes: product.notes,
                            imagePath: product.imagePath,
                          ),
                        );
                      } else {
                        // 对于分类没有改变的产品，直接添加回列表
                        updatedProducts.add(product);
                      }
                    }
                    // 用更新后的产品列表替换旧的 _products 列表
                    _products = updatedProducts;
                    // --- 修改到这里结束 ---

                    // 更新过滤后的列表
                    _filterCategories(); // 这会重新过滤 _products
                  }
                });
                _saveCategories();
                _saveProducts(); // 确保保存更新后的产品列表
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

  // 删除分类的对话框
  void _showDeleteCategoryDialog(String categoryToDelete) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('删除分类'),
          content: Text('您确定要删除分类 "$categoryToDelete" 吗？此操作将同时删除该分类下的所有产品。'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.black,
              ),
              child: const Text('删除'),
              onPressed: () {
                setState(() {
                  _categories.remove(categoryToDelete);
                  _products.removeWhere((p) => p.category == categoryToDelete);

                  // 删除后更新过滤列表
                  _filterCategories();
                  // 刷新数据以确保 CategoryProductListScreen 返回时也能看到最新数据
                  _loadData(); 
                });
                _saveCategories();
                _saveProducts();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分类管理'), // AppBar 标题改为“分类管理”
        // 在 AppBar 底部添加搜索框
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 8.0), // 留出一点边距
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索分类...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterCategories(); // 清空搜索框后，重新过滤显示所有分类
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant, // 使用主题颜色
              ),
            ),
          ),
        ),
        // 移除排序和筛选动作按钮
        actions: [], 
      ),
      // 移除 Drawer，因为它现在的主体内容就是分类列表
      // drawer: Drawer(...), // 完全删除这个 Drawer 部分

      body: _filteredCategories.isEmpty && _searchController.text.isNotEmpty
          ? const Center(
              child: Text('没有找到匹配的分类。'),
            )
          : ListView.builder(
              itemCount: _filteredCategories.length + 1, // +1 是为了“添加新分类”按钮
              itemBuilder: (context, index) {
                if (index < _filteredCategories.length) {
                  final category = _filteredCategories[index];
                  return ListTile(
                    leading: const Icon(Icons.folder_open),
                    title: Text(category),
                    onTap: () async {
                      // 导航到 CategoryProductListScreen，显示该分类下的产品
                      final productsInCategory = _products.where((p) => p.category == category).toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryProductListScreen(
                            categoryName: category,
                            allCategories: _categories, // 保持传递所有分类
                          ),
                        ),
                      );
                      // 从产品列表页返回时，重新加载数据以更新分类列表（如分类被删除，或产品数量变化等）
                      _loadData();
                    },
                    trailing: category != '未分类' // "未分类"不允许编辑或删除
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () {
                                  _showEditCategoryDialog(category);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () {
                                  _showDeleteCategoryDialog(category);
                                },
                              ),
                            ],
                          )
                        : null,
                  );
                } else {
                  // 列表的最后一个条目用于添加新分类
                  return ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('添加新分类'),
                    onTap: _showAddCategoryDialog,
                  );
                }
              },
            ),
      // 移除浮动动作按钮 (FAB)，因为添加产品现在在 CategoryProductListScreen 中完成
      floatingActionButton: null, 
    );
  }
}