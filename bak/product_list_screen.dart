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
  String _currentCategory = '未分类'; 
  
  TextEditingController _searchController = TextEditingController(); // 用于分类搜索的控制器
  List<String> _filteredCategories = []; // 过滤后的分类列表，用于显示

  @override
  void initState() {
    super.initState();
    _loadData();
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
                      List<Product> updatedProducts = [];
                      for (var product in _products) {
                        if (product.category == oldCategoryName) {
                          updatedProducts.add(
                            Product(
                              id: product.id,
                              name: product.name,
                              quantity: product.quantity,
                              unit: product.unit,
                              totalPrice: product.totalPrice,
                              category: newCategoryName,
                              notes: product.notes,
                              imagePath: product.imagePath,
                            ),
                          );
                        } else {
                          updatedProducts.add(product);
                        }
                      }
                      _products = updatedProducts;
                      _filterCategories();
                    }
                  });
                  _saveCategories();
                  _saveProducts();
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
                  _filterCategories();
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
        title: const Text('性价比计算器'), 
        centerTitle: true, // 将标题居中
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
        actions: [], // 移除了分类管理按钮
      ),
      body: Column( // 使用 Column 包装整个 body 内容
        children: [
          Expanded( // 使分类列表占用可用空间
            child: _filteredCategories.isEmpty && _searchController.text.isNotEmpty
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
                          trailing: category != '未分类'
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
          ),
          // 添加底部开发者信息
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
            child: Column(
              children: const [
                Text(
                  '开发者-Cui707',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  'Email-cui19991999@126.com',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newProduct = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditProductScreen(
                categories: _categories, // 传递所有分类
              ),
            ),
          );
          if (newProduct != null && newProduct is Product) {
            setState(() {
              _products.add(newProduct);
              // 添加新产品后需要重新加载数据，以确保分类列表正确更新（如果新产品创建了新分类）
              _loadData(); 
            });
            await _productStorage.saveProducts(_products);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}