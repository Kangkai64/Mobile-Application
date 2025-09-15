import 'package:flutter/material.dart';
import 'job_details_screen.dart';
import '../models/work_orders.dart';
import 'package:provider/provider.dart';
import '../providers/work_orders_provider.dart';

class ActiveJobsScreen extends StatelessWidget {
  const ActiveJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkOrdersProvider>();
    final inProgress = provider.filterOrders(status: 'IN PROGRESS');
    final pending = provider.filterOrders(status: 'PENDING');
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Active Jobs',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.green[600], size: 20),
                const SizedBox(width: 4),
                Text(
                  '${inProgress.length} Active',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // In Progress section
            Container(
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
                    children: [
                      Icon(Icons.access_time, color: Colors.green[600], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'In Progress',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (inProgress.isEmpty)
                    Text('No in-progress jobs', style: TextStyle(color: Colors.grey[600]))
                  else
                    ...inProgress.map((o) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildJobCard(
                            context,
                            o.id,
                            o.priority.toUpperCase(),
                            o.status,
                            o.customerNotes.isNotEmpty ? o.customerNotes : 'Work Order',
                            o.internalNotes,
                            o.vehicleName,
                            o.licensePlate,
                            o.assignedStaffId,
                            '',
                          ),
                        )),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pending section
            Container(
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
                    children: [
                      Icon(Icons.schedule, color: Colors.orange[600], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Pending',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (pending.isEmpty)
                    Text('No pending jobs', style: TextStyle(color: Colors.grey[600]))
                  else
                    ...pending.map((o) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildJobCard(
                            context,
                            o.id,
                            o.priority.toUpperCase(),
                            o.status,
                            o.customerNotes.isNotEmpty ? o.customerNotes : 'Work Order',
                            o.internalNotes,
                            o.vehicleName,
                            o.licensePlate,
                            o.assignedStaffId,
                            '',
                          ),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
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
  ) {
    Color priorityColor = priority == 'HIGH' ? Colors.red : 
                         priority == 'MEDIUM' ? Colors.orange : Colors.green;
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
              customerName: '',
              customerEmail: '',
              customerPhone: '',
              customerAddress: '',
              vehicleVin: '',
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
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
