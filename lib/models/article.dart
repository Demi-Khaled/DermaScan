import 'package:flutter/material.dart';

class Article {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String content;

  const Article({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.content,
  });
}
