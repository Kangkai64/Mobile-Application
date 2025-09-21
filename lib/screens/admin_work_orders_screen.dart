import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/work_orders.dart';
import '../providers/work_orders_provider.dart';
import '../services/work_orders_service.dart';
import '../utils/currency_formatter.dart';
import 'job_details_screen.dart';

class AdminWorkOrdersScreen extends StatefulWidget {
  const AdminWorkOrdersScreen({super.key});

  @override
  State<AdminWorkOrdersScreen> createState() => _AdminWorkOrdersScreenState();
}

class _AdminWorkOrdersScreenState extends State<AdminWorkOrdersScreen> {
  final WorkOrdersService _workOrdersService = WorkOrdersService();
  String? _selectedStatus;
  String? _selectedPriority;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWorkOrders();
  }

  Future<void> _loadWorkOrders() async {
    setState(() => _isLoading = true);
    final workOrdersProvider = context.read<WorkOrdersProvider>();
    await workOrdersProvider.loadWorkOrders();
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workOrdersProvider = context.watch<WorkOrdersProvider>();
    final List<WorkOrders> allOrders = workOrdersProvider.workOrders ?? [];
    
    // Apply filters
    List<WorkOrders> filteredOrders = allOrders.where((order) {
      bool statusMatch = _selectedStatus == null || 
          order.status == _selectedStatus;
      bool priorityMatch = _selectedPriority == null || 
          order.priority == _selectedPriority;
      bool searchMatch = _searchQuery.isEmpty ||
          order.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.licensePlate.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.customerNotes.toLowerCase().contains(_searchQuery.toLowerCase());
      
      return statusMatch && priorityMatch && searchMatch;
    }).toList();

    // Sort by creation date (newest first)
    filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Work Orders Management',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadWorkOrders,
            icon: Icon(Icons.refresh, color: Colors.green),
          ),
          PopupMenuButton<String>(
            onSelected: _handleStatusUpdate,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'bulk_pending',
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Mark Selected as Pending'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'bulk_in_progress',
                child: Row(
                  children: [
                    Icon(Icons.play_arrow, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Mark Selected as In Progress'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'bulk_completed',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.purple),
                    SizedBox(width: 8),
                    Text('Mark Selected as Completed'),
                  ],
                ),
              ),
            ],
            child: Icon(Icons.more_vert, color: Colors.green),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search work orders...',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: Icon(Icons.clear),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 12),
                
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', _selectedStatus == null, () {
                        setState(() => _selectedStatus = null);
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pending', _selectedStatus == 'Pending', () {
                        setState(() => _selectedStatus = 'Pending');
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('In Progress', _selectedStatus == 'In Progress', () {
                        setState(() => _selectedStatus = 'In Progress');
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Completed', _selectedStatus == 'Completed', () {
                        setState(() => _selectedStatus = 'Completed');
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Signed Off', _selectedStatus == 'Signed Off', () {
                        setState(() => _selectedStatus = 'Signed Off');
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Cancelled', _selectedStatus == 'Cancelled', () {
                        setState(() => _selectedStatus = 'Cancelled');
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('On Hold', _selectedStatus == 'On Hold', () {
                        setState(() => _selectedStatus = 'On Hold');
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Accepted', _selectedStatus == 'Accepted', () {
                        setState(() => _selectedStatus = 'Accepted');
                      }),
                      const SizedBox(width: 16),
                      _buildPriorityChip('High', _selectedPriority == 'High', () {
                        setState(() => _selectedPriority = _selectedPriority == 'High' ? null : 'High');
                      }),
                      const SizedBox(width: 8),
                      _buildPriorityChip('Medium', _selectedPriority == 'Medium', () {
                        setState(() => _selectedPriority = _selectedPriority == 'Medium' ? null : 'Medium');
                      }),
                      const SizedBox(width: 8),
                      _buildPriorityChip('Low', _selectedPriority == 'Low', () {
                        setState(() => _selectedPriority = _selectedPriority == 'Low' ? null : 'Low');
                      }),
                      const SizedBox(width: 8),
                      _buildPriorityChip('Urgent', _selectedPriority == 'Urgent', () {
                        setState(() => _selectedPriority = _selectedPriority == 'Urgent' ? null : 'Urgent');
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Work Orders List
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text('Loading work orders...'),
                      ],
                    ),
                  )
                : filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.work_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No work orders found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters or search terms',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return _buildWorkOrderCard(order);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Colors.green.withOpacity(0.2),
      checkmarkColor: Colors.green,
    );
  }

  Widget _buildPriorityChip(String label, bool isSelected, VoidCallback onTap) {
    Color chipColor = label == 'High' 
        ? Colors.red 
        : label == 'Medium' 
            ? Colors.orange 
            : Colors.green;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: chipColor.withOpacity(0.2),
      checkmarkColor: chipColor,
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkOrderCard(WorkOrders order) {
    Color priorityColor = order.priority == 'High'
        ? Colors.red
        : order.priority == 'Medium'
            ? Colors.orange
            : order.priority == 'Urgent'
                ? Colors.purple
                : Colors.green;
    
    Color statusColor = _getStatusColor(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToJobDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.id,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          order.priority.toUpperCase(),
                          style: TextStyle(
                            color: priorityColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusDisplay(order.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Customer Info
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.customerName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Vehicle Info
              Row(
                children: [
                  Icon(Icons.directions_car, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    order.vehicleName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.licensePlate,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Amount and Payment Status
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyFormatter.format(order.totalAmount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: order.paymentStatus == 'Paid' 
                          ? Colors.green.withOpacity(0.1)
                          : order.paymentStatus == 'Overdue'
                              ? Colors.red.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.paymentStatus,
                      style: TextStyle(
                        fontSize: 12,
                        color: order.paymentStatus == 'Paid' 
                            ? Colors.green
                            : order.paymentStatus == 'Overdue'
                                ? Colors.red
                                : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Notes Preview
              if (order.customerNotes.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.customerNotes,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              const SizedBox(height: 8),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showStatusUpdateDialog(order),
                    icon: Icon(Icons.edit, size: 16),
                    label: Text('Update Status'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showDeleteConfirmation(order),
                    icon: Icon(Icons.delete, size: 16),
                    label: Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'In Progress':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Accepted':
        return Colors.blue;
      case 'On Hold':
        return Colors.red;
      case 'Completed':
        return Colors.purple;
      case 'Cancelled':
        return Colors.red.shade700;
      case 'Signed Off':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplay(String status) {
    switch (status) {
      case 'In Progress':
        return 'In Progress';
      case 'Pending':
        return 'Pending';
      case 'Accepted':
        return 'Accepted';
      case 'On Hold':
        return 'On Hold';
      case 'Completed':
        return 'Completed';
      case 'Cancelled':
        return 'Cancelled';
      case 'Signed Off':
        return 'Signed Off';
      default:
        return status;
    }
  }

  void _navigateToJobDetails(WorkOrders order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobDetailsScreen(
          workOrder: order.id,
          status: order.status,
          title: order.customerNotes.isNotEmpty ? order.customerNotes : 'Work Order',
          description: order.internalNotes,
          vehicle: order.vehicleName,
          licensePlate: order.licensePlate,
          assignedTo: order.assignedStaffId,
          customerName: order.customerName,
          customerEmail: order.customerEmail,
          customerPhone: order.customerPhone,
          customerAddress: order.customerAddress,
          vehicleVin: order.vehicles?.vin ?? '',
          customerSignature: order.customerSignature,
        ),
      ),
    );
  }

  void _showStatusUpdateDialog(WorkOrders order) {
    // Normalize the current status to match dropdown values
    String currentStatus = order.status.trim().toUpperCase();
    String newStatus = _normalizeStatusForDropdown(currentStatus);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Update Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Work Order: ${order.id}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: newStatus,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: [
                  'Pending',
                  'In Progress',
                  'Completed',
                  'Cancelled',
                  'On Hold',
                  'Accepted',
                  'Signed Off',
                ].map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status),
                )).toList(),
                onChanged: (value) {
                  setState(() => newStatus = value!);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _updateWorkOrderStatus(order.id, newStatus);
                Navigator.pop(context);
              },
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  String _normalizeStatusForDropdown(String status) {
    switch (status.trim().toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'IN PROGRESS':
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      case 'ON HOLD':
      case 'ON_HOLD':
        return 'On Hold';
      case 'ACCEPTED':
        return 'Accepted';
      case 'SIGNED OFF':
      case 'SIGNED_OFF':
        return 'Signed Off';
      default:
        return 'Pending'; // Default fallback
    }
  }

  void _showDeleteConfirmation(WorkOrders order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Work Order'),
        content: Text('Are you sure you want to delete work order ${order.id}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _deleteWorkOrder(order.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateWorkOrderStatus(String workOrderId, String newStatus) async {
    try {
      setState(() => _isLoading = true);
      await _workOrdersService.updateWorkOrder(workOrderId, {
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Refresh the work orders
      final workOrdersProvider = context.read<WorkOrdersProvider>();
      await workOrdersProvider.refreshAll();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteWorkOrder(String workOrderId) async {
    try {
      setState(() => _isLoading = true);
      await _workOrdersService.deleteWorkOrder(workOrderId);
      
      // Refresh the work orders
      final workOrdersProvider = context.read<WorkOrdersProvider>();
      await workOrdersProvider.refreshAll();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Work order deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting work order: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleStatusUpdate(String action) {
    // This would handle bulk status updates for selected items
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bulk update feature coming soon')),
    );
  }
}
