import 'package:flutter/material.dart';
import '../models/work_orders.dart';
import '../services/work_orders_service.dart';

class WorkOrdersProvider extends ChangeNotifier {
  WorkOrdersProvider._internal();
  static final _instance = WorkOrdersProvider._internal();
  factory WorkOrdersProvider() => _instance;

  final WorkOrdersService _service = WorkOrdersService();

  List<WorkOrders>? _workOrders;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetch;

  // public getters
  List<WorkOrders>? get workOrders => _workOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  //getters
  List<WorkOrders> filterOrders({String? status, String? priority}) {
    return _workOrders
            ?.where((o) =>
                (status == null || o.status.toUpperCase() == status.toUpperCase()) &&
                (priority == null || o.priority.toUpperCase() == priority.toUpperCase()))
            .toList() ??
        [];
  }

  bool _isCacheValid() {
    if (_lastFetch == null) return false;
    return DateTime.now().difference(_lastFetch!) < const Duration(minutes: 5);
  }

  // Load data and save in cache to share with all screens
  Future<void> loadWorkOrders({bool forceRefresh = false}) async {
    if (_isLoading) return;

    if (_workOrders != null && !forceRefresh && _isCacheValid()) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _workOrders = await _service.fetchAll();
      _lastFetch = DateTime.now();
      _error = null;
    }
    catch (error) {
      _error = error.toString();
    }
    finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateWorkOrder(String id, Map<String, dynamic> updates) async {
    try {
      final success = await _service.updateWorkOrder(id, updates);
      if (success && _workOrders != null) {
        // Update local cache
        final index = _workOrders!.indexWhere((order) => order.id == id);
        if (index != -1) {
          final updatedOrder = WorkOrders.fromJson({
            ..._workOrders![index].toJson(),
            ...updates,
          });
          _workOrders![index] = updatedOrder;
          notifyListeners();
        }
      }
      return success;
    }
    catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addWorkOrder(Map<String, dynamic> data) async {
    try {
      final newOrder = await _service.createWorkOrder(data);
      if (newOrder != null && _workOrders != null) {
        _workOrders!.insert(0, newOrder);
        notifyListeners();
        return true;
      }
      return false;
    }
    catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteWorkOrder(String id) async {
    try {
      final success = await _service.deleteWorkOrder(id);
      if (success && _workOrders != null) {
        _workOrders! .removeWhere((order) => order.id == id);
        notifyListeners();
      }
      return success;
    }
    catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refresh() => loadWorkOrders(forceRefresh: true);

}