import 'package:flutter/material.dart';
import 'package:costperformanceclaculatorcui707/models/product.dart';
import 'package:costperformanceclaculatorcui707/screens/add_edit_product_screen.dart';
import 'package:costperformanceclaculatorcui707/services/product_storage.dart';
import 'dart:io';

class CategoryProductListScreen extends StatefulWidget {
  final String categoryName;
  // products 初始传递过来，但后续会通过 _refreshProducts 从存储中加载最新
  final List<Product> products; 
  final List<String> allCategories; // 用于 AddEditProductScreen

  const CategoryProductListScreen({
    super.key,
    required this.categoryName,
    required this.products,
    required this.allCategories,
  });

  @override
  State<CategoryProductListScreen> createState() => _CategoryProductListScreenState();
}

class _CategoryProductListScreenState extends State<CategoryProductListScreen> {
  final ProductStorage _productStorage = ProductStorage();
  List<Product> _currentCategoryProducts = [];

  @override
  void initState() {
    super.initState();
    // Initial load: filter products based on the category name
    // Then immediately refresh to ensure latest data from storage
    _refreshProducts(); 
  }

  // Refresh current category product list by loading latest data from storage
  Future<void> _refreshProducts() async {
    final allProducts = await _productStorage.loadProducts();
    setState(() {
      _currentCategoryProducts = allProducts.where((p) => p.category == widget.categoryName).toList();
      _sortAndHighlightProducts(); // Re-sort and highlight
    });
  }

  // Sort products by price-per-unit and identify best/worst value
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
    // 从 AddEditProductScreen 返回后，重新加载并保存所有产品数据
    // 这里的逻辑已经处理了final属性的问题：我们不会修改旧产品的final属性，
    // 而是通过创建新产品或替换旧产品的方式来更新列表。
    final allProducts = await _productStorage.loadProducts();
    
    if (product == null) { // 如果是添加新产品
      allProducts.add(result);
    } else { // 如果是编辑现有产品
      // 找到要编辑的旧产品在 allProducts 中的索引
      final index = allProducts.indexWhere((p) => p.id == result.id);
      if (index != -1) {
        // 直接替换旧产品为从编辑界面返回的新产品对象
        // 新产品对象 (result) 包含了所有最新的属性，包括可能的分类修改
        allProducts[index] = result;
      } else {
        // 这通常不应该发生，除非编辑了一个不存在的产品，但为了健壮性可以加上
        allProducts.add(result); 
      }
    }
    
    await _productStorage.saveProducts(allProducts); // 保存所有产品
    await _refreshProducts(); // 刷新当前分类的产品列表显示
  }
}

  // Show delete product dialog
  void _showDeleteProductDialog(Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('删除产品'),
          content: Text('您确定要删除产品 "${product.name}" 吗？'),
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
              onPressed: () async {
                // Remove from the current category list (for UI update)
                setState(() {
                  _currentCategoryProducts.removeWhere((p) => p.id == product.id);
                });
                
                // Remove from all products and save to storage
                final allProducts = await _productStorage.loadProducts();
                allProducts.removeWhere((p) => p.id == product.id);
                await _productStorage.saveProducts(allProducts);
                
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Show product bottom sheet menu (for Android/iOS)
  void _showProductBottomSheetMenu(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('编辑产品'),
                onTap: () {
                  Navigator.pop(bc);
                  _navigateToAddEditProductScreen(product: product);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('删除产品'),
                onTap: () {
                  Navigator.pop(bc);
                  _showDeleteProductDialog(product);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Show Windows platform right-click context menu
  void _showWindowsContextMenu(BuildContext context, Product product, Offset tapPosition) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromLTRB(
      tapPosition.dx,
      tapPosition.dy,
      overlay.size.width - tapPosition.dx,
      overlay.size.height - tapPosition.dy,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('编辑产品'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete),
            title: Text('删除产品'),
          ),
        ),
      ],
    ).then((String? value) {
      if (value == null) return;

      if (value == 'edit') {
        _navigateToAddEditProductScreen(product: product);
      } else if (value == 'delete') {
        _showDeleteProductDialog(product);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Product? bestValueProduct;
    Product? worstValueProduct;

    if (_currentCategoryProducts.isNotEmpty) {
      bestValueProduct = _currentCategoryProducts.first;
      worstValueProduct = _currentCategoryProducts.last;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.categoryName} - 产品列表'), // AppBar title shows current category
      ),
      body: _currentCategoryProducts.isEmpty
          ? Center(
              child: Text('"${widget.categoryName}" 分类下没有产品，点击右下角按钮添加一个吧！'),
            )
          : ListView.builder(
              itemCount: _currentCategoryProducts.length,
              itemBuilder: (context, index) {
                final product = _currentCategoryProducts[index];
                Color? cardColor;

                if (bestValueProduct != null && product.id == bestValueProduct.id) {
                  cardColor = Colors.green.shade100;
                } else if (worstValueProduct != null && product.id == worstValueProduct.id) {
                  cardColor = Colors.red.shade100;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  color: cardColor,
                  child: GestureDetector(
                    onSecondaryTapDown: (details) {
                      _showWindowsContextMenu(context, product, details.globalPosition);
                    },
                    onLongPress: () {
                      if (Theme.of(context).platform != TargetPlatform.windows) {
                        _showProductBottomSheetMenu(context, product);
                      }
                    },
                    child: InkWell( // Use InkWell for tap effect
                      onTap: () {
                        _navigateToAddEditProductScreen(product: product);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0), // Add some internal padding
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start, // Align content to the top
                          children: [
                            // Column 1: Total Price and Quantity/Unit
                            Expanded(
                              flex: 2, // Relative width
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
                            // Column 2: Product Name and Price-Per-Unit (性价比)
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    maxLines: 2, // Max two lines for long names
                                    overflow: TextOverflow.ellipsis, // Ellipsis for overflow
                                  ),
                                  Text(
                                    '性价比: ¥${product.pricePerUnit.toStringAsFixed(2)} / ${product.unit}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            // Column 3: Notes
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0), // Left margin for separation
                                child: Text(
                                  product.notes != null && product.notes!.isNotEmpty
                                      ? '备注: ${product.notes!}'
                                      : '无备注',
                                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                                  maxLines: 3, // Max three lines for notes
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            // Column 4: Image
                            if (product.imagePath != null && File(product.imagePath!).existsSync())
                              SizedBox(
                                width: 70, // Fixed width for image
                                height: 70, // Fixed height for image
                                child: Image.file(
                                  File(product.imagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.image_not_supported, size: 50, color: Colors.red);
                                  },
                                ),
                              )
                            else
                              const SizedBox( // Placeholder if no image exists
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateToAddEditProductScreen(); // Add new product to current category
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}