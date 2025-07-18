// lib/screens/category_product_list_screen.dart

import 'package:flutter/material.dart';
import 'package:costperformanceclaculatorcui707/models/product.dart';
import 'package:costperformanceclaculatorcui707/screens/add_edit_product_screen.dart'; // 确保这个导入是正确的
import 'package:costperformanceclaculatorcui707/services/product_storage.dart';
import 'dart:io';
import 'dart:math'; // Import for Random class

class CategoryProductListScreen extends StatefulWidget {
  final String categoryName;
  final List<String> allCategories; // 传递所有分类，用于编辑产品时选择

  const CategoryProductListScreen({
    super.key,
    required this.categoryName,
    required this.allCategories,
  });

  @override
  State<CategoryProductListScreen> createState() => _CategoryProductListScreenState();
}

class _CategoryProductListScreenState extends State<CategoryProductListScreen> {
  final ProductStorage _productStorage = ProductStorage();
  List<Product> _allProducts = []; // 存储所有产品
  List<Product> _currentCategoryProducts = []; // 存储当前分类的产品
  String? _randomlySelectedProductId; // New: Stores the ID of the randomly selected product for highlighting

  @override
  void initState() {
    super.initState();
    _refreshProducts();
  }

  Future<void> _refreshProducts() async {
    _allProducts = await _productStorage.loadProducts();
    setState(() {
      _currentCategoryProducts = _allProducts
          .where((product) => product.category == widget.categoryName)
          .toList();
      _sortAndHighlightProducts();
      // Reset random selection when products are refreshed, unless it's the same product.
      // For simplicity, we'll clear it for now to avoid stale highlighting.
      _randomlySelectedProductId = null; 
    });
  }

  void _sortAndHighlightProducts() {
    _currentCategoryProducts.sort((a, b) => a.pricePerUnit.compareTo(b.pricePerUnit));
  }

  void _navigateToAddEditProductScreen({Product? product}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(
          product: product,
          categories: widget.allCategories, // 传递所有分类
          defaultCategory: widget.categoryName, // 新产品默认选中当前分类
        ),
      ),
    );

    if (result != null && result is Product) {
      final allProducts = await _productStorage.loadProducts();

      if (product == null) {
        allProducts.add(result);
      } else {
        final index = allProducts.indexWhere((p) => p.id == result.id);
        if (index != -1) {
          allProducts[index] = result;
        } else {
          allProducts.add(result);
        }
      }

      await _productStorage.saveProducts(allProducts);
      await _refreshProducts();
    }
  }

  void _showDeleteProductDialog(Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('删除产品'),
          content: Text('确定要删除产品 "${product.name}" 吗？'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('删除'),
              onPressed: () async {
                _allProducts.removeWhere((p) => p.id == product.id);
                await _productStorage.saveProducts(_allProducts);
                await _refreshProducts();
                if (mounted) Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showProductBottomSheetMenu(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('编辑'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAddEditProductScreen(product: product);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('删除'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteProductDialog(product);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWindowsContextMenu(BuildContext context, Product product, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
      items: <PopupMenuEntry>[
        PopupMenuItem(
          value: 'edit',
          child: const Text('编辑'),
          onTap: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _navigateToAddEditProductScreen(product: product);
            });
          },
        ),
        PopupMenuItem(
          value: 'delete',
          child: const Text('删除'),
          onTap: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showDeleteProductDialog(product);
            });
          },
        ),
      ],
    );
  }

  Future<void> _deleteAllProductsInCategory() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('删除所有商品'),
          content: Text('确定要删除 "${widget.categoryName}" 分类下的所有商品吗？此操作不可撤销。'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('删除'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _allProducts.removeWhere((product) => product.category == widget.categoryName);
      await _productStorage.saveProducts(_allProducts);
      await _refreshProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除 "${widget.categoryName}" 分类下的所有商品')),
        );
      }
    }
  }

  // New: Method to select a random product, highlight it, and move it to the top
  void _selectRandomProduct() {
    if (_currentCategoryProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前分类中没有商品。')),
      );
      return;
    }

    final random = Random();
    int randomIndex = random.nextInt(_currentCategoryProducts.length);
    Product selectedProduct = _currentCategoryProducts[randomIndex];

    setState(() {
      _randomlySelectedProductId = selectedProduct.id;
      
      // Remove the selected product from its current position
      _currentCategoryProducts.removeAt(randomIndex);
      // Insert it at the beginning of the list
      _currentCategoryProducts.insert(0, selectedProduct);
      
      // Optionally re-sort the rest of the list, but the request only says "置顶"
      // If full re-sorting of the remaining items is desired:
      // List<Product> sortedRemaining = _currentCategoryProducts.sublist(1);
      // sortedRemaining.sort((a, b) => a.pricePerUnit.compareTo(b.pricePerUnit));
      // _currentCategoryProducts = [selectedProduct, ...sortedRemaining];
    });
  }

  @override
  Widget build(BuildContext context) {
    Product? bestValueProduct;
    Product? worstValueProduct;

    if (_currentCategoryProducts.isNotEmpty) {
      // Find best and worst based on the currently sorted list
      // Note: If _selectRandomProduct changes order, these might need recalculation
      // or ensure _sortAndHighlightProducts is called before finding these.
      bestValueProduct = _currentCategoryProducts.reduce((a, b) => a.pricePerUnit < b.pricePerUnit ? a : b);
      worstValueProduct = _currentCategoryProducts.reduce((a, b) => a.pricePerUnit > b.pricePerUnit ? a : b);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.categoryName} - 产品列表'),
        actions: [
          ElevatedButton(
            onPressed: _deleteAllProductsInCategory,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, // 设置背景颜色为红色
              foregroundColor: Colors.black, // 设置文本颜色为黑色
            ),
            child: const Text('删除所有商品'),
          ),
          const SizedBox(width: 8), // 可选：添加一些间距
        ],
      ),
      body: Column( // New: Wrap body content in a Column
        children: [
          Expanded( // New: Make ListView fill available space
            child: _currentCategoryProducts.isEmpty
                ? Center(
                    child: Text('"${widget.categoryName}" 分类下没有产品，点击右下角按钮添加一个吧！'),
                  )
                : ListView.builder(
                    itemCount: _currentCategoryProducts.length,
                    itemBuilder: (context, index) {
                      final product = _currentCategoryProducts[index];
                      Color? cardColor;
                      
                      // Determine base color (best/worst value)
                      if (bestValueProduct != null && product.id == bestValueProduct.id) {
                        cardColor = Colors.green.shade100;
                      } else if (worstValueProduct != null && product.id == worstValueProduct.id) {
                        cardColor = Colors.red.shade100;
                      }

                      // Apply random selection highlight if applicable
                      final bool isRandomlySelected = product.id == _randomlySelectedProductId;
                      final Color? finalCardColor = isRandomlySelected ? Colors.lightBlueAccent.withOpacity(0.3) : cardColor;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        color: finalCardColor, // Use the determined final color
                        elevation: isRandomlySelected ? 8 : 2, // Higher elevation for selected
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: isRandomlySelected ? const BorderSide(color: Colors.blue, width: 2) : BorderSide.none,
                        ),
                        child: GestureDetector(
                          onSecondaryTapDown: (details) {
                            _showWindowsContextMenu(context, product, details.globalPosition);
                          },
                          onLongPress: () {
                            if (Theme.of(context).platform != TargetPlatform.windows) {
                              _showProductBottomSheetMenu(context, product);
                            }
                          },
                          child: InkWell(
                            onTap: () {
                              _navigateToAddEditProductScreen(product: product);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '总价: ¥${product.totalPrice.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '数量: ${product.quantity} ${product.unit}',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '性价比: ¥${product.pricePerUnit.toStringAsFixed(2)} / ${product.unit}',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text(
                                        product.notes != null && product.notes!.isNotEmpty
                                            ? '备注: ${product.notes!}'
                                            : '无备注',
                                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  if (product.imagePath != null && File(product.imagePath!).existsSync())
                                    SizedBox(
                                      width: 70,
                                      height: 70,
                                      child: Image.file(
                                        File(product.imagePath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.image_not_supported, size: 50, color: Colors.red);
                                        },
                                      ),
                                    )
                                  else
                                    const SizedBox(
                                      width: 70,
                                      height: 70,
                                      child: Center(
                                        child: Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // New: "选择困难-随机" button at the bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _selectRandomProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent, // Light blue background
                foregroundColor: Colors.black, // Black text
                minimumSize: const Size.fromHeight(50), // Make button wide
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
              ),
              child: const Text(
                '选择困难 - 随机',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateToAddEditProductScreen();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}