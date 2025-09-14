import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'workload.dart';

class JobDetailsScreen extends StatefulWidget {
  final String workOrder;
  final String status;
  final String title;
  final String description;
  final String vehicle;
  final String licensePlate;
  final String assignedTo;

  const JobDetailsScreen({
    super.key,
    required this.workOrder,
    required this.status,
    required this.title,
    required this.description,
    required this.vehicle,
    required this.licensePlate,
    required this.assignedTo,
  });

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  late String currentStatus;
  bool isUpdating = false;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // Initialize with passed status
    currentStatus = "Pending";
  }

  Future<void> updateJobStatus(String newStatus) async {
    setState(() {
      isUpdating = true;
    });

    try {
      final responese = await supabase
          .from('WorkOrders')
          .update({
        'status' : newStatus,
        'updated_at' : DateTime.now().toIso8601String(),
      }).eq('id', widget.workOrder);

      setState(() {
        currentStatus = newStatus;
        isUpdating = false;
      });

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
                          currentStatus,
                          style: TextStyle(
                            color: _getStatusColor(currentStatus),
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
                  _buildInfoRow(Icons.person, widget.assignedTo),
                  _buildInfoRow(Icons.phone, '(555) 123-4567'),
                  _buildInfoRow(Icons.email, 'john.smith@email.com'),
                  _buildInfoRow(Icons.location_on, '123 Main St, City, State 12345'),
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
                        _buildInfoRow(Icons.confirmation_number, 'VIN: 1FTFW1ET5LFC12345'),
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
                          Expanded(child: _buildStatusButton('Pending', Colors.orange, currentStatus == 'Pending', () => updateJobStatus('Pending'))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildStatusButton('Accepted', Colors.blue, currentStatus == 'Accepted', () => updateJobStatus('Accepted'))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildStatusButton('In Progress', Colors.green, currentStatus == 'In Progress', () => updateJobStatus('In Progress'))),
                          const SizedBox(width: 8)
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child:
                          Row(
                            children: [
                              Expanded(child: _buildStatusButton('On Hold', Colors.red, currentStatus == 'On Hold', () => updateJobStatus('On Hold'))),
                              const SizedBox(width: 8),
                              Expanded(child: _buildStatusButton('Completed', Colors.purple, currentStatus == 'Completed', () => updateJobStatus('Completed'))),
                              const SizedBox(width: 8),
                              Expanded(child: _buildStatusButton('Signed Off', Colors.grey, currentStatus == 'Signed Off', () => updateJobStatus('Signed Off'))),
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
