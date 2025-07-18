// lib/screens/add_edit_product_screen.dart

import 'package:flutter/material.dart';
import 'package:costperformanceclaculatorcui707/models/product.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class AddEditProductScreen extends StatefulWidget {
  final Product? product;
  final List<String> categories; // 传递所有分类
  final String? defaultCategory; // 用于新产品设置默认分类

  const AddEditProductScreen({
    super.key,
    this.product,
    required this.categories,
    this.defaultCategory,
  });

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _totalPriceController;
  late TextEditingController _notesController;
  late String _selectedUnit;
  late String _selectedCategory;
  String? _imagePath;

  final List<String> _units = [
    '个', '克', '千克', '毫升', '升', '斤', '公斤'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name);
    _quantityController = TextEditingController(text: widget.product?.quantity.toString());
    _totalPriceController = TextEditingController(text: widget.product?.totalPrice.toString());
    _notesController = TextEditingController(text: widget.product?.notes);
    _selectedUnit = widget.product?.unit != null && _units.contains(widget.product!.unit)
        ? widget.product!.unit
        : _units[0];
    _selectedCategory = widget.product?.category ??
        (widget.defaultCategory != null && widget.categories.contains(widget.defaultCategory)
            ? widget.defaultCategory!
            : widget.categories.isNotEmpty ? widget.categories[0] : '默认分类');

    _imagePath = widget.product?.imagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _totalPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // 修改 _pickImage 方法，增加选择来源的逻辑
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final String fileName = path.basename(pickedFile.path);
      final String localPath = path.join(appDir.path, fileName);
      
      final File newImage = await File(pickedFile.path).copy(localPath);

      setState(() {
        _imagePath = newImage.path;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imagePath = null;
    });
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final newProduct = Product(
        id: widget.product?.id,
        name: _nameController.text,
        quantity: double.parse(_quantityController.text),
        unit: _selectedUnit,
        totalPrice: double.parse(_totalPriceController.text),
        category: _selectedCategory,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        imagePath: _imagePath,
      );
      Navigator.pop(context, newProduct);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? '添加产品' : '编辑产品'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '产品名称'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入产品名称';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _totalPriceController,
                decoration: const InputDecoration(labelText: '总价'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入总价';
                  }
                  if (double.tryParse(value) == null) {
                    return '请输入有效数字';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: '数量'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入数量';
                  }
                  if (double.tryParse(value) == null) {
                    return '请输入有效数字';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedUnit,
                decoration: const InputDecoration(labelText: '单位'),
                items: _units.map((String unit) {
                  return DropdownMenuItem<String>(
                    value: unit,
                    child: Text(unit),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedUnit = newValue!;
                  });
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: '分类'),
                items: widget.categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: '备注 (可选)'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              // 修改图片选择按钮区域
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.camera), // 拍照按钮
                    child: const Text('拍照'),
                  ),
                  const SizedBox(width: 10), // 增加间隔
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.gallery), 
                    child: const Text('选择图片'),
                  ),
                  if (_imagePath != null) ...[
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _removeImage,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('移除图片'),
                    ),
                  ],
                ],
              ),
              if (_imagePath != null && File(_imagePath!).existsSync())
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Image.file(
                    File(_imagePath!),
                    height: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
                    },
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProduct,
                child: Text(widget.product == null ? '添加产品' : '保存更改'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}