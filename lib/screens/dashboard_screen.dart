import 'package:flutter/material.dart';
import 'job_details_screen.dart';
import '../models/work_orders.dart';
import 'package:provider/provider.dart';
import '../providers/work_orders_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _selectedStatus; // null => All Jobs
  @override
  Widget build(BuildContext context) {
    final workOrdersProvider = context.watch<WorkOrdersProvider>();
    final List<WorkOrders> allOrders = workOrdersProvider.workOrders ?? [];
    final List<WorkOrders> orders =
        workOrdersProvider.filterOrders(status: _selectedStatus);

    int countByStatus(String status) => allOrders
        .where((o) => (o.status).toUpperCase() == status.toUpperCase())
        .length;

    int countToday() {
      DateTime now = DateTime.now();
      bool isSameDay(DateTime a, DateTime b) =>
          a.year == b.year && a.month == b.month && a.day == b.day;
      return allOrders.where((o) => isSameDay(o.scheduledDate, now)).length;
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Welcome back!',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(Icons.calendar_today, color: Colors.green),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workshop name
            const Text(
              'Greenstem Workshop',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Job summary cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryBox('${orders.length}', 'Total Jobs'),
                _buildSummaryBox('${countToday()}', "Today's Jobs"),
                _buildSummaryBox(
                  '${countByStatus('IN PROGRESS')}',
                  'In Progress',
                ),
                _buildSummaryBox('${countByStatus('COMPLETED')}', 'Completed'),
              ],
            ),
            const SizedBox(height: 24),

            // Filter tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterTab(
                    'All Jobs (${allOrders.length})',
                    _selectedStatus == null,
                    () {
                      setState(() => _selectedStatus = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterTab(
                    'Pending (${countByStatus('PENDING')})',
                    _selectedStatus?.toUpperCase() == 'PENDING',
                    () {
                      setState(() => _selectedStatus = 'PENDING');
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterTab(
                    'In Progress (${countByStatus('IN PROGRESS')})',
                    _selectedStatus?.toUpperCase() == 'IN PROGRESS',
                    () {
                      setState(() => _selectedStatus = 'IN PROGRESS');
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterTab(
                    'Completed (${countByStatus('COMPLETED')})',
                    _selectedStatus?.toUpperCase() == 'COMPLETED',
                    () {
                      setState(() => _selectedStatus = 'COMPLETED');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Job list
            if (orders.isEmpty)
              Center(
                child: Column(
                  children: const [
                    SizedBox(height: 24),
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Loading work orders...'),
                  ],
                ),
              )
            else
              ...orders.map(
                (o) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildJobCardWithOrder(
                    context,
                    o,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widget _buildSummaryCard(String title, String value, Color color) {
  Widget _buildSummaryBox(String count, String label) {
    return Container(
      width: 85,
      height: 70,
      padding: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(150),
            blurRadius: 5,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String text, bool isSelected, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey[300]!,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildJobCardWithOrder(BuildContext context, WorkOrders o) {
    // Convert total_time (seconds) to h m s string
    String timeSpent = '';
    final int seconds = o.totalTime ?? 0;
    if (seconds > 0) {
      int hours = seconds ~/ 3600;
      int minutes = (seconds % 3600) ~/ 60;
      int secs = seconds % 60;
      timeSpent = '${hours}h ${minutes}m ${secs}s';
    } else {
      timeSpent = '0h 0m 0s';
    }
    return _buildJobCard(
      context,
      o.id,
      o.priority.toUpperCase(),
      o.status,
      o.customerNotes.isNotEmpty ? o.customerNotes : 'Work Order',
      o.internalNotes,
      o.vehicleName,
      o.licensePlate,
      o.assignedStaffId,
      timeSpent,
      customerName: o.customerName,
      customerEmail: o.customerEmail,
      customerPhone: o.customerPhone,
      customerAddress: o.customerAddress,
      vehicleVin: o.vehicles?.vin ?? '',
    );
  }

  Widget _buildJobCard(
    BuildContext context,
    String workOrder,
    String priority,
    String status,
    String title,
    String description,
    String vehicle,
    String licensePlate,
    String assignedTo,
    String timeSpent,
    {String customerName = '', String customerEmail = '', String customerPhone = '', String customerAddress = '', String vehicleVin = ''}
  ) {
    Color priorityColor = priority == 'HIGH'
        ? Colors.red
        : priority == 'MEDIUM'
            ? Colors.orange
            : Colors.green;
    Color statusColor = _statusColor(status);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailsScreen(
              workOrder: workOrder,
              status: status,
              title: title,
              description: description,
              vehicle: vehicle,
              licensePlate: licensePlate,
              assignedTo: assignedTo,
              customerName: customerName,
              customerEmail: customerEmail,
              customerPhone: customerPhone,
              customerAddress: customerAddress,
              vehicleVin: vehicleVin,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  workOrder,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _statusDisplay(status),
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
            // Job title
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            // Job description
            Text(
              description,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 12),
            // Vehicle details
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                children: [
                  Icon(Icons.directions_car, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    vehicle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    licensePlate,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Assigned to: $assignedTo',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Time spent: $timeSpent',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.trim().toUpperCase()) {
      case 'IN PROGRESS':
      case 'IN_PROGRESS':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPTED':
        return Colors.blue;
      case 'ON HOLD':
      case 'ON_HOLD':
        return Colors.red;
      case 'COMPLETED':
        return Colors.purple;
      case 'SIGNED OFF':
      case 'SIGNED_OFF':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _statusDisplay(String status) {
    switch (status.trim().toUpperCase()) {
      case 'IN PROGRESS':
      case 'IN_PROGRESS':
        return 'IN PROGRESS';
      case 'PENDING':
        return 'PENDING';
      case 'ACCEPTED':
        return 'ACCEPTED';
      case 'ON HOLD':
      case 'ON_HOLD':
        return 'ON HOLD';
      case 'COMPLETED':
        return 'COMPLETED';
      case 'SIGNED OFF':
      case 'SIGNED_OFF':
        return 'SIGNED OFF';
      default:
        return status.toUpperCase();
    }
  }
}
