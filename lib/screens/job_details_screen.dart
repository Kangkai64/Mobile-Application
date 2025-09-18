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
  // Update total_time in WorkOrders table for finished assigned parts
  Future<void> _updateTotalTimeToWorkOrder() async {
    Duration total = Duration.zero;
    for (final part in assignedParts) {
      final startedAt = part['part_started_at'];
      final completedAt = part['part_completed_at'];
      if (startedAt != null && completedAt != null) {
        final start = DateTime.parse(startedAt);
        final end = DateTime.parse(completedAt);
        final diff = end.difference(start) - Duration(hours: 8); // Subtract 8 hours
        if (!diff.isNegative) total += diff;
      }
    }
    final provider = context.read<WorkOrdersProvider>();
    await provider.updateWorkOrder(widget.workOrder, {
      'total_time': total.inSeconds, // Save as seconds
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
  TextEditingController _notesController = TextEditingController();
  bool _isSavingNotes = false;

  @override
  void initState() {
    super.initState();
    currentStatusDisplay = _toDisplayStatus(widget.status);
    _loadAssignedParts();
    _notesController.text = widget.description; // Default to description, update if notes available
  }

  Future<void> _updateNotes() async {
    setState(() { _isSavingNotes = true; });
    final provider = context.read<WorkOrdersProvider>();
    final success = await provider.updateWorkOrder(widget.workOrder, {
      'internal_notes': _notesController.text,
      'updated_at': DateTime.now().toIso8601String(),
    });
    setState(() { _isSavingNotes = false; });
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notes updated.'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update notes.'), backgroundColor: Colors.red, duration: Duration(seconds: 2)),
      );
    }
  }
  // Format completed date for user-friendly display
  String _formatCompletedDate(dynamic completedAt) {
    try {
      DateTime dt = completedAt is DateTime
        ? completedAt
        : DateTime.parse(completedAt.toString());
      // Format: Sep 18, 2025, 8:40 AM
      return '${_monthShort(dt.month)} ${dt.day}, ${dt.year}, ${_formatHourMinute(dt)}';
    } catch (e) {
      return completedAt.toString();
    }
  }

  String _monthShort(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _formatHourMinute(DateTime dt) {
    int hour = dt.hour;
    String ampm = hour >= 12 ? 'PM' : 'AM';
    int hour12 = hour % 12 == 0 ? 12 : hour % 12;
    String minute = dt.minute.toString().padLeft(2, '0');
    return '$hour12:$minute $ampm';
  }
  // Helper to check if any other part is active or paused
  bool _anyOtherActiveOrPaused(String partId) {
    return _partTimers.entries.any((e) {
      final id = e.key;
      final paused = _partPaused[id] == true;
      final started = _partTimers[id] != null && _partTimers[id] != Duration.zero;
      final completed = assignedParts.firstWhere((p) => p['id'] == id, orElse: () => {})['part_completed_at'] != null;
      return ((started && !paused && !completed) || (started && paused && !completed)) && id != partId;
    });
  }
  void _resumeTimer(String partId) {
    _partPaused[partId] = false;
    _partLastTick[partId] = DateTime.now();
    setState(() {});
    _tick(partId);
  }
  // Timer state for each part
  Map<String, Duration> _partTimers = {};
  Map<String, bool> _partPaused = {};
  Map<String, DateTime?> _partLastTick = {};

  void _startTimer(String partId) {
    // Restrict to only one active timer or paused timer
    bool anyActiveOrPaused = _partTimers.entries.any((e) {
      final id = e.key;
      final paused = _partPaused[id] == true;
      final started = _partTimers[id] != null && _partTimers[id] != Duration.zero;
      final completed = assignedParts.firstWhere((p) => p['id'] == id, orElse: () => {})['part_completed_at'] != null;
      return ((started && !paused && !completed) || (started && paused && !completed)) && id != partId;
    });
    if (anyActiveOrPaused) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot start another time track while another is active or paused.')),
      );
      return;
    }
    _partTimers[partId] = _partTimers[partId] ?? Duration.zero;
    _partLastTick[partId] = DateTime.now();
    _partPaused[partId] = false;
    setState(() {});
    _tick(partId);
  }

  void _tick(String partId) async {
    if (_partPaused[partId] == true) return;
    await Future.delayed(Duration(seconds: 1));
    if (_partPaused[partId] == true) return;
    final now = DateTime.now();
    final last = _partLastTick[partId] ?? now;
    final elapsed = now.difference(last);
    setState(() {
      _partTimers[partId] = (_partTimers[partId] ?? Duration.zero) + elapsed;
      _partLastTick[partId] = now;
    });
    _tick(partId);
  }

  void _pauseTimer(String partId) {
    _partPaused[partId] = true;
    setState(() {});
  }

  void _stopTimer(String partId) {
    _partPaused[partId] = true;
    setState(() {});
  }

  Future<void> _completeTimer(String partId, Map<String, dynamic> part) async {
    // Save completion time to backend
    final provider = context.read<WorkOrdersProvider>();
    final now = DateTime.now().toIso8601String();
    await provider.updateWorkOrderPart(partId, {
      'part_completed_at': now,
    });
    await _loadAssignedParts();
    await _updateTotalTimeToWorkOrder();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = twoDigits(d.inHours);
    final m = twoDigits(d.inMinutes.remainder(60));
    final s = twoDigits(d.inSeconds.remainder(60));
    return "$h:$m:$s";
  }
  Future<void> _startPart(Map<String, dynamic> part) async {
    final provider = context.read<WorkOrdersProvider>();
    final now = DateTime.now().toUtc().toIso8601String();
    final success = await provider.updateWorkOrderPart(part['id'], {
      'part_started_at': now,
    });
    if (success) {
      await _loadAssignedParts();
    }
  }

  Future<void> _pausePart(Map<String, dynamic> part) async {
    // TODO: Implement logic to set is_paused in backend
    print('Pause part: \'${part['id']}\'');
  }

  Future<void> _resumePart(Map<String, dynamic> part) async {
    // TODO: Implement logic to unset is_paused in backend
    print('Resume part: \'${part['id']}\'');
  }

  Future<void> _stopPart(Map<String, dynamic> part) async {
    // TODO: Implement logic to set part_completed_at in backend (or stop timer)
    print('Stop part: \'${part['id']}\'');
  }

  Future<void> _completePart(Map<String, dynamic> part) async {
    // TODO: Implement logic to set part_completed_at in backend
    print('Complete part: \'${part['id']}\'');
  }
  late String currentStatusDisplay;
  bool isUpdating = false;
  List<Map<String, dynamic>> assignedParts = [];
  bool isLoadingParts = false;


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

  Future<void> _loadAssignedParts() async {
    try {
      setState(() {
        isLoadingParts = true;
      });

      final provider = context.read<WorkOrdersProvider>();
      final parts = await provider.getAssignedPartsForWorkOrder(widget.workOrder);

      if (parts != null) {
        setState(() {
          assignedParts = parts;
          // Ensure timer state is initialized for each part
          for (final part in parts) {
            final partId = part['id'];
            final startedAt = part['part_started_at'];
            final completedAt = part['part_completed_at'];
            final isPaused = _partPaused[partId] ?? false;
            if (startedAt != null && completedAt == null && !isPaused) {
              // Calculate elapsed time from startedAt using UTC
              final startTime = DateTime.parse(startedAt).toUtc();
              final now = DateTime.now().toUtc();
              _partTimers[partId] = now.difference(startTime);
              _partLastTick[partId] = now;
              // Start ticking for running timers
              _tick(partId);
            } else {
              _partTimers.putIfAbsent(partId, () => Duration.zero);
              _partLastTick.putIfAbsent(partId, () => null);
            }
            _partPaused.putIfAbsent(partId, () => false);
          }
        });
      }
    } catch (e) {
      print('Error loading assigned parts: $e');
    } finally {
      setState(() {
        isLoadingParts = false;
      });
    }
  }

  // Helper widgets and methods
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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

  String _getTotalTimeSummary() {
    Duration total = Duration.zero;
    for (final part in assignedParts) {
      final startedAt = part['part_started_at'];
      final completedAt = part['part_completed_at'];
      if (startedAt != null && completedAt != null) {
        final start = DateTime.parse(startedAt);
        final end = DateTime.parse(completedAt);
        final diff = end.difference(start) - Duration(hours: 8); // Subtract 8 hours
        if (!diff.isNegative) total += diff;
      }
    }
    final hours = total.inHours;
    final minutes = total.inMinutes % 60;
    final seconds = total.inSeconds % 60;
    return '${hours}h ${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Job Details',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
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
                color: Theme.of(context).colorScheme.surface,
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.description,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                    const SizedBox(height: 12),
                  Text('Internal Notes:', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Add notes for this work order...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.save),
                          label: Text(_isSavingNotes ? 'Saving...' : 'Save Notes'),
                          onPressed: _isSavingNotes ? null : _updateNotes,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Customer & Vehicle section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
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
                  Text(
                    'Customer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
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
                  Text(
                    'Vehicle',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
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
                color: Theme.of(context).colorScheme.surface,
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
                  Text(
                    'Update Job Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
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

            // Assigned Parts section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
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
                  Text(
                    'Assigned Parts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (isLoadingParts)
                    Center(child: CircularProgressIndicator(),)
                  else if (assignedParts.where((part) => part['part_completed_at'] == null).isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No unfinished assigned parts.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    // Unfinished assigned parts
                    ...assignedParts.where((part) => part['part_completed_at'] == null).map((part) {
                      final partId = part['id'];
                      final partName = part['Parts'] != null ? part['Parts']['name'] : part['name'] ?? 'N/A';
                      final partCategory = part['Parts'] != null ? part['Parts']['category'] : part['category'] ?? 'N/A';
                      final partPrice = part['Parts'] != null ? part['Parts']['unit_price'] : part['unit_price'] ?? 0;
                      final quantity = part['quantity'] ?? 0;
                      final totalPrice = part['total_price'] ?? (partPrice * quantity);
                      final notes = part['notes'] ?? '';
                      final startedAt = part['part_started_at'];
                      final completedAt = part['part_completed_at'];
                      final isStarted = startedAt != null;
                      final isCompleted = completedAt != null;
                      final isPaused = _partPaused[partId] == true;
                      final timerValue = _partTimers[partId] ?? Duration.zero;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
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
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(partName ?? 'N/A', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                                      const SizedBox(height: 4),
                                      Text('Category: $partCategory', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12)),
                                      if (notes.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text('Notes: $notes', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12, fontStyle: FontStyle.italic)),
                                      ],
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Qty: $quantity', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text('Unit: \$${(partPrice ?? 0).toStringAsFixed(2)}', style: TextStyle(color: Colors.green[700], fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text('Total: \$${(totalPrice ?? 0).toStringAsFixed(2)}', style: TextStyle(color: Colors.green[900], fontSize: 13, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (isStarted && !isCompleted && !isPaused) ...[
                              Center(
                                child: Text(
                                  _formatDuration(timerValue),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF22C55E),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    ),
                                    icon: const Icon(Icons.pause),
                                    label: const Text('Pause'),
                                    onPressed: () {
                                      _pauseTimer(partId);
                                    },
                                  ),
                                ],
                              ),
                            ]
                            else if (isStarted && !isCompleted && isPaused) ...[
                              Center(
                                child: Text(
                                  _formatDuration(timerValue),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF22C55E),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (!_anyOtherActiveOrPaused(partId))
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF22C55E),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      ),
                                      icon: const Icon(Icons.play_arrow),
                                      label: const Text('Resume'),
                                      onPressed: () {
                                        _resumeTimer(partId);
                                      },
                                    ),
                                  if (!_anyOtherActiveOrPaused(partId))
                                    const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    ),
                                    icon: const Icon(Icons.check),
                                    label: const Text('Complete'),
                                    onPressed: () {
                                      _completeTimer(partId, part);
                                    },
                                  ),
                                ],
                              ),
                            ]
                            else if (!isStarted) ...[
                              if (!_anyOtherActiveOrPaused(partId))
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _startPart(part);
                                      _startTimer(partId);
                                    },
                                    child: const Text('Start'),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Finished Assigned Parts section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
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
                  Text(
                    'Service History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (assignedParts.where((part) => part['part_completed_at'] != null).isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No finished assigned parts.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    // Calculate total sum price
                    Builder(
                      builder: (context) {
                        final finishedParts = assignedParts.where((part) => part['part_completed_at'] != null);
                        double totalSum = 0;
                        for (final part in finishedParts) {
                          final partPrice = part['Parts'] != null ? part['Parts']['unit_price'] : part['unit_price'] ?? 0;
                          final quantity = part['quantity'] ?? 0;
                          final totalPrice = part['total_price'] ?? (partPrice * quantity);
                          totalSum += (totalPrice is num ? totalPrice.toDouble() : 0);
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Total Price of Finished Parts: \$${totalSum.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.green[900],
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                    ...assignedParts.where((part) => part['part_completed_at'] != null).map((part) {
                      final partName = part['Parts'] != null ? part['Parts']['name'] : part['name'] ?? 'N/A';
                      final partCategory = part['Parts'] != null ? part['Parts']['category'] : part['category'] ?? 'N/A';
                      final partPrice = part['Parts'] != null ? part['Parts']['unit_price'] : part['unit_price'] ?? 0;
                      final quantity = part['quantity'] ?? 0;
                      final totalPrice = part['total_price'] ?? (partPrice * quantity);
                      final notes = part['notes'] ?? '';
                      final completedAt = part['part_completed_at'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(partName ?? 'N/A', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                                  const SizedBox(height: 4),
                                  Text('Category: $partCategory', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12)),
                                  if (notes.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text('Notes: $notes', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12, fontStyle: FontStyle.italic)),
                                  ],
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Qty: $quantity', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text('Unit: \$${(partPrice ?? 0).toStringAsFixed(2)}', style: TextStyle(color: Colors.green[700], fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text('Total: \$${(totalPrice ?? 0).toStringAsFixed(2)}', style: TextStyle(color: Colors.green[900], fontSize: 13, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Completed: ' + (completedAt != null
                                      ? _formatCompletedDate(completedAt)
                                      : ''),
                                    style: TextStyle(color: Colors.green[900], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ], // <-- Add this missing closing bracket for the children list
              ),
            ),
            const SizedBox(height: 16),

            // Time Summary section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
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
                    'Time Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (assignedParts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No time summary available.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    ...assignedParts.map((part) {
                      final partName = part['Parts'] != null ? part['Parts']['name'] : part['name'] ?? 'N/A';
                      final completedAt = part['part_completed_at'];
                      final startedAt = part['part_started_at'];
                      Duration duration = Duration.zero;
                      if (startedAt != null && completedAt != null) {
                        final start = DateTime.parse(startedAt);
                        final end = DateTime.parse(completedAt);
                        duration = end.difference(start) - Duration(hours: 8); // Subtract 8 hours
                      }
                      if (duration.isNegative) duration = Duration.zero;
                      final hours = duration.inHours;
                      final minutes = duration.inMinutes % 60;
                      final seconds = duration.inSeconds % 60;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(partName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    if (completedAt != null && startedAt != null)
                                      Text('${hours}h ${minutes}m ${seconds}s', style: TextStyle(color: Colors.green)),
                                ],
                              ),
                            ),
                            if (completedAt != null && startedAt != null)
                                Text('${hours}h ${minutes}m ${seconds}s', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }).toList(),
                    const Divider(height: 24, thickness: 2),
                    Row(
                      children: [
                          const Icon(Icons.access_time, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                            'Total Time: ' + _getTotalTimeSummary(),
                            style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
