import 'package:flutter/material.dart';

class BranchProvider extends ChangeNotifier {
  final List<String> branches = [
    'Центральный филиал',
    'Филиал на Юге',
    'Филиал на Севере',
  ];

  String? _selectedBranch;
  String? get selectedBranch => _selectedBranch;

  void setBranch(String b) {
    _selectedBranch = b;
    notifyListeners();
  }

  void clearBranch() {
    _selectedBranch = null;
    notifyListeners();
  }
}
