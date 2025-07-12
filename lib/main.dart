// main.dart

import 'package:flutter/material.dart';
import 'package:costperformanceclaculatorcui707/screens/product_list_screen.dart'; // 导入主界面

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '性价比计算器', // 应用在任务管理器等地方显示的名称
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ProductListScreen(), // 设置主界面
    );
  }
}