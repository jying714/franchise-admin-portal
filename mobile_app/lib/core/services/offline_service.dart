// lib/core/services/offline_service.dart

// ignore_for_file: unused_import

import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:convert';
import 'package:franchise_mobile_app/core/models/customization.dart';
import 'package:franchise_mobile_app/core/models/menu_item.dart';
import 'package:flutter/material.dart' as material hide Banner, BannerLocation;
import 'package:franchise_mobile_app/core/models/order.dart' as order_model;
import 'package:franchise_mobile_app/core/models/feedback_entry.dart'
    as feedback_model;
import 'package:franchise_mobile_app/core/models/chat.dart';
import 'package:franchise_mobile_app/core/models/nutrition_info.dart';

class OfflineService {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'doughboys.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE menu_items (
            id TEXT PRIMARY KEY,
            category TEXT,
            categoryId TEXT,
            name TEXT,
            price REAL,
            description TEXT,
            image TEXT,
            includedIngredients TEXT,
            customizationGroups TEXT,
            optionalAddOns TEXT,
            taxCategory TEXT,
            availability INTEGER,
            sku TEXT,
            dietaryTags TEXT,
            allergens TEXT,
            prepTime INTEGER,
            nutrition TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE cart (
            id TEXT PRIMARY KEY,
            userId TEXT,
            items TEXT,
            total REAL
          )
        ''');
        await db.execute('''
          CREATE TABLE feedback (
            id TEXT PRIMARY KEY,
            rating INTEGER,
            comment TEXT,
            categories TEXT,
            timestamp INTEGER,
            userId TEXT,
            anonymous INTEGER,
            orderId TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE chats (
            id TEXT PRIMARY KEY,
            userId TEXT,
            lastMessage TEXT,
            lastMessageAt INTEGER,
            status TEXT,
            userName TEXT
          )
    ''');
      },
      // If you ever need to upgrade with new fields, implement onUpgrade here.
    );
  }

  // --- MENU ITEMS ---

  Future<void> cacheMenuItems(List<MenuItem> items) async {
    final db = await database;
    await db.delete('menu_items');
    for (var item in items) {
      await db.insert('menu_items', {
        'id': item.id,
        'category': item.category,
        'categoryId': item.categoryId,
        'name': item.name,
        'price': item.price,
        'description': item.description,
        'image': item.image,
        'includedIngredients': jsonEncode(item.includedIngredients ?? []),
        'customizationGroups': jsonEncode(item.customizationGroups ?? []),
        'optionalAddOns': jsonEncode(item.optionalAddOns ?? []),
        'customizations': jsonEncode(
            item.customizations.map((c) => c.toFirestore()).toList()),
        'taxCategory': item.taxCategory,
        'availability': item.availability ? 1 : 0,
        'sku': item.sku,
        'dietaryTags': item.dietaryTags.join(','),
        'allergens': item.allergens.join(','),
        'prepTime': item.prepTime,
        'nutrition':
            item.nutrition != null ? jsonEncode(item.nutrition!.toMap()) : null,
      });
    }
  }

  Future<List<MenuItem>> getCachedMenuItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('menu_items');
    return maps.map((map) {
      return MenuItem(
        id: map['id'],
        category: map['category'],
        categoryId: map['categoryId'] ?? '',
        name: map['name'],
        price: map['price'],
        description: map['description'],
        image: map['image'],
        taxCategory: map['taxCategory'],
        availability: map['availability'] == 1,
        sku: map['sku'],
        dietaryTags: map['dietaryTags'] != null && map['dietaryTags'] != ''
            ? map['dietaryTags'].split(',').where((e) => e.isNotEmpty).toList()
            : <String>[],
        allergens: map['allergens'] != null && map['allergens'] != ''
            ? map['allergens'].split(',').where((e) => e.isNotEmpty).toList()
            : <String>[],
        prepTime: map['prepTime'],
        nutrition: map['nutrition'] != null
            ? NutritionInfo.fromFirestore(jsonDecode(map['nutrition']))
            : null,
        includedIngredients: map['includedIngredients'] != null &&
                map['includedIngredients'] != ''
            ? List<Map<String, dynamic>>.from(
                jsonDecode(map['includedIngredients']))
            : null,
        customizationGroups: map['customizationGroups'] != null &&
                map['customizationGroups'] != ''
            ? List<Map<String, dynamic>>.from(
                jsonDecode(map['customizationGroups']))
            : null,
        optionalAddOns: map['optionalAddOns'] != null &&
                map['optionalAddOns'] != ''
            ? List<Map<String, dynamic>>.from(jsonDecode(map['optionalAddOns']))
            : null,
        // ---- FIXED: Pass customizations as required ----
        customizations: (map['customizations'] != null &&
                map['customizations'] != '')
            ? (jsonDecode(map['customizations']) as List)
                .map((e) =>
                    Customization.fromFirestore(Map<String, dynamic>.from(e)))
                .toList()
            : [],
      );
    }).toList();
  }

  // --- CART ---

  Future<void> cacheCart(order_model.Order order) async {
    final db = await database;
    await db.insert(
      'cart',
      {
        'id': order.id,
        'userId': order.userId,
        'items': jsonEncode(order.items.map((e) => e.toMap()).toList()),
        'total': order.total,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<order_model.Order?> getCachedCart(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cart',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    if (maps.isEmpty) return null;
    // Note: Deserialization of items needs to match your order item model!
    return order_model.Order(
      id: maps[0]['id'],
      userId: maps[0]['userId'],
      items: [], // To be extended if needed
      subtotal: 0.0,
      tax: 0.0,
      deliveryFee: 0.0,
      discount: 0.0,
      total: maps[0]['total'],
      deliveryType: '',
      time: '',
      status: '',
      timestamp: DateTime.now(),
      estimatedTime: 0,
      timestamps: {},
    );
  }

  // --- FEEDBACK (queue for offline submission) ---

  Future<void> cacheFeedback(feedback_model.FeedbackEntry feedback) async {
    final db = await database;
    await db.insert(
      'feedback',
      {
        'id': feedback.id,
        'rating': feedback.rating,
        'comment': feedback.comment,
        'categories': feedback.categories.join(','),
        'timestamp': feedback.timestamp.millisecondsSinceEpoch,
        'userId': feedback.userId,
        'anonymous': feedback.anonymous ? 1 : 0,
        'orderId': feedback.orderId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<feedback_model.FeedbackEntry>> getCachedFeedback() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('feedback');
    return maps.map((map) {
      return feedback_model.FeedbackEntry(
        id: map['id'],
        rating: map['rating'],
        comment: map['comment'],
        categories: map['categories'] != null && map['categories'] != ''
            ? map['categories'].split(',').where((e) => e.isNotEmpty).toList()
            : <String>[],
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
        userId: map['userId'],
        anonymous: map['anonymous'] == 1,
        orderId: map['orderId'] ?? '',
      );
    }).toList();
  }

  // --- Queue Feedback for Sync ---
  Future<void> queueFeedback(feedback_model.FeedbackEntry feedback) async {
    await cacheFeedback(feedback);
  }

  // --- Remove Queued Feedback after Sync ---
  Future<void> removeQueuedFeedback(String feedbackId) async {
    final db = await database;
    await db.delete(
      'feedback',
      where: 'id = ?',
      whereArgs: [feedbackId],
    );
  }

  // --- CHATS ---

  Future<void> cacheChat(Chat chat) async {
    final db = await database;
    await db.insert(
      'chats',
      {
        'id': chat.id,
        'userId': chat.userId,
        'lastMessage': chat.lastMessage,
        'lastMessageAt': chat.lastMessageAt.millisecondsSinceEpoch,
        'status': chat.status,
        'userName': chat.userName ?? '',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Chat>> getCachedChats(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chats',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return maps.map((map) {
      return Chat(
        id: map['id'],
        userId: map['userId'],
        lastMessage: map['lastMessage'] ?? '',
        lastMessageAt: map['lastMessageAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageAt'])
            : DateTime.now(),
        status: map['status'],
        userName: map['userName'],
      );
    }).toList();
  }
}
