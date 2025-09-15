import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/work_orders_provider.dart';

class JobDetailsScreen extends StatefulWidget {
  final String workOrder;
  final String status;
  final String title;
  final String description;
  final String vehicle;
  final String licensePlate;
  final String assignedTo;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String customerAddress;
  final String vehicleVin;

  const JobDetailsScreen({
    super.key,
    required this.workOrder,
    required this.status,
    required this.title,
    required this.description,
    required this.vehicle,
    required this.licensePlate,
    required this.assignedTo,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.customerAddress,
    required this.vehicleVin,
  });

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  late String currentStatusDisplay;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    // Normalize incoming status (DB may pass uppercase)
    currentStatusDisplay = _toDisplayStatus(widget.status);
  }

  // Helpers to normalize status text between UI and DB
  String _toDisplayStatus(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'ACCEPTED':
        return 'Accepted';
      case 'IN PROGRESS':
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'ON HOLD':
      case 'ON_HOLD':
        return 'On Hold';
      case 'COMPLETED':
        return 'Completed';
      case 'SIGNED OFF':
      case 'SIGNED_OFF':
        return 'Signed Off';
      default:
        return raw;
    }
  }

  String _toDbStatus(String display) {
    switch (display) {
      case 'Pending':
        return 'PENDING';
      case 'Accepted':
        return 'ACCEPTED';
      case 'In Progress':
        return 'IN PROGRESS';
      case 'On Hold':
        return 'ON HOLD';
      case 'Completed':
        return 'COMPLETED';
      case 'Signed Off':
        return 'SIGNED OFF';
      default:
        return display.toUpperCase();
    }
  }

  Future<void> updateJobStatus(String newStatus) async {
    setState(() {
      isUpdating = true;
    });

    try {
      final provider = context.read<WorkOrdersProvider>();
      final success = await provider.updateWorkOrder(widget.workOrder, {
        // DB has a CHECK constraint expecting title-cased values
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (success) {
        setState(() {
          currentStatusDisplay = newStatus;
          isUpdating = false;
        });
      } else {
        setState(() {
          isUpdating = false;
        });
        if (mounted) {
          final providerError = context.read<WorkOrdersProvider>().error;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to update status${providerError != null ? ": $providerError" : ''}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ));
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job status updated to $newStatus'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          )
        );
      }
    }
    catch (error) {
      setState(() {
        isUpdating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update status: ${error.toString()}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Job Details',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job overview card
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.workOrder,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          currentStatusDisplay,
                          style: TextStyle(
                            color: _getStatusColor(currentStatusDisplay),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Customer & Vehicle section
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
                  const Text(
                    'Customer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.person, widget.customerName.isNotEmpty ? widget.customerName : widget.assignedTo),
                  if (widget.customerEmail.isNotEmpty)
                    _buildInfoRow(Icons.email, widget.customerEmail),
                  if (widget.customerPhone.isNotEmpty)
                    _buildInfoRow(Icons.phone, widget.customerPhone),
                  if (widget.customerAddress.isNotEmpty)
                    _buildInfoRow(Icons.location_on, widget.customerAddress),
                  const SizedBox(height: 16),
                  const Text(
                    'Vehicle',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(Icons.directions_car, widget.vehicle),
                        _buildInfoRow(Icons.confirmation_number, 'VIN: ${widget.vehicleVin.isNotEmpty ? widget.vehicleVin : 'N/A'}'),
                        _buildInfoRow(Icons.credit_card, 'License Plate: ${widget.licensePlate}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Update Job Status section
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
                  const Text(
                    'Update Job Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (isUpdating)
                    Center (
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8,),
                          Text('Updating status...', style: TextStyle(color: Colors.grey),)
                        ],
                      ),
                    )
                  else
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildStatusButton('Pending', Colors.orange, currentStatusDisplay == 'Pending', () => updateJobStatus('Pending'))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildStatusButton('Accepted', Colors.blue, currentStatusDisplay == 'Accepted', () => updateJobStatus('Accepted'))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildStatusButton('In Progress', Colors.green, currentStatusDisplay == 'In Progress', () => updateJobStatus('In Progress'))),
                          const SizedBox(width: 8)
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child:
                          Row(
                            children: [
                              Expanded(child: _buildStatusButton('On Hold', Colors.red, currentStatusDisplay == 'On Hold', () => updateJobStatus('On Hold'))),
                              const SizedBox(width: 8),
                              Expanded(child: _buildStatusButton('Completed', Colors.purple, currentStatusDisplay == 'Completed', () => updateJobStatus('Completed'))),
                              const SizedBox(width: 8),
                              Expanded(child: _buildStatusButton('Signed Off', Colors.grey, currentStatusDisplay == 'Signed Off', () => updateJobStatus('Signed Off'))),
                              const SizedBox(width: 8)
                            ],
                          ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Time Tracking section
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
                  const Text(
                    'Time Tracking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Task Description',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'What are you working on?',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.green),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String text, Color color, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Accepted':
        return Colors.blue;
      case 'In Progress':
        return Colors.green;
      case 'On Hold':
        return Colors.red;
      case 'Completed':
        return Colors.purple;
      case 'Signed Off':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
