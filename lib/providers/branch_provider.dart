import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BranchProvider extends ChangeNotifier {
  String? _selectedBranch;

  String? get selectedBranch => _selectedBranch;

  BranchProvider() {
    _loadBranch(); // загружаем при создании
  }

  void setBranch(String branch) async {
    _selectedBranch = branch;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_branch', branch);
  }

  Future<void> _loadBranch() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedBranch = prefs.getString('selected_branch');
    notifyListeners();
  }

  void clearBranch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_branch');
    _selectedBranch = null;
    notifyListeners();
  }
}
