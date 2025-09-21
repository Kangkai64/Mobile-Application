
    import 'dart:convert';
    import 'package:supabase_flutter/supabase_flutter.dart';
    import 'package:flutter/material.dart';
    import 'package:provider/provider.dart';
    import '../providers/work_orders_provider.dart';
    import 'package:signature/signature.dart';
    import 'dart:io';
    import 'package:path/path.dart' as path;
    import 'package:path_provider/path_provider.dart';
    import 'package:image/image.dart' as img;
    import '../services/image_service.dart';
    import 'package:image_picker/image_picker.dart';
    import '../utils/currency_formatter.dart';

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
    final String? customerSignature;

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
      this.customerSignature,
    });

    @override
    State<JobDetailsScreen> createState() => _JobDetailsScreenState();
  }

  class _JobDetailsScreenState extends State<JobDetailsScreen> {
  Future<void> _deleteWorkOrderImage(int idx) async {
    final provider = context.read<WorkOrdersProvider>();
    final imageUrl = _workOrderImageUrls[idx];
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final imageService = ImageService();
      await imageService.deleteImage(imageUrl, 'WorkOrder');
      List<String> updatedUrls = List<String>.from(_workOrderImageUrls);
      updatedUrls.removeAt(idx);
      await provider.updateWorkOrder(widget.workOrder, {
        'image_url': updatedUrls,
        'updated_at': DateTime.now().toIso8601String(),
      });
      setState(() {
        _workOrderImageUrls = updatedUrls;
      });
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo deleted successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete photo: $e'), backgroundColor: Colors.red),
      );
    }
  }
    final ImagePicker _picker = ImagePicker();
  List<String> _workOrderImageUrls = [];
    bool _isUploadingPhoto = false;
    final SignatureController _signatureController = SignatureController(
      penStrokeWidth: 2,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    bool _showSignatureDialog = false;
    bool _isProcessingSignOff = false;
    String? _customerSignature;
    bool _isLoadingSignature = true;
    TextEditingController _notesController = TextEditingController();
    bool _isSavingNotes = false;

    Future<void> _updateNotes() async {
      setState(() {
        _isSavingNotes = true;
      });
      final provider = context.read<WorkOrdersProvider>();
      final success = await provider.updateWorkOrder(widget.workOrder, {
        'internal_notes': _notesController.text,
        'updated_at': DateTime.now().toIso8601String(),
      });
      setState(() {
        _isSavingNotes = false;
      });
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notes updated.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update notes.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
    Future<void> _fetchWorkOrder() async {
      try {
        final supabase = Supabase.instance.client;
        final workOrderObj = await supabase
            .from('WorkOrders')
            .select('customer_signature, status')
            .eq('id', widget.workOrder)
            .single();
        debugPrint('[FETCH] workOrderObj: $workOrderObj');
        setState(() {
          _customerSignature = workOrderObj?['customer_signature'] ?? '';
          currentStatusDisplay = workOrderObj?['status'] ?? widget.status;
          // Load image URLs from provider for persistence
          final imageUrlData = workOrderObj?['image_url'];
          if (imageUrlData is List) {
            _workOrderImageUrls = List<String>.from(imageUrlData);
          } else if (imageUrlData is String && imageUrlData.isNotEmpty) {
            _workOrderImageUrls = imageUrlData.split(',').map((e) => e.trim()).toList();
          } else {
            _workOrderImageUrls = [];
          }
          _isLoadingSignature = false;
        });
        debugPrint('[FETCH] setState: _customerSignature=$_customerSignature, currentStatusDisplay=$currentStatusDisplay');
      } catch (e) {
        debugPrint('Error fetching work order: $e');
        setState(() {
          _isLoadingSignature = false;
        });
      }
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

    @override
    void dispose() {
      _signatureController.dispose();
      super.dispose();
    }

    // Update total_time in WorkOrders table for finished assigned parts
    Future<void> _updateTotalTimeToWorkOrder() async {
      Duration total = Duration.zero;
      for (final part in assignedParts) {
        final startedAt = part['part_started_at'];
        final completedAt = part['part_completed_at'];
        if (startedAt != null && completedAt != null) {
          final start = DateTime.parse(startedAt);
          final end = DateTime.parse(completedAt);
          final diff =
              end.difference(start) - Duration(hours: 8); // Subtract 8 hours
          if (!diff.isNegative) total += diff;
        }
      }
      final provider = context.read<WorkOrdersProvider>();
      await provider.updateWorkOrder(widget.workOrder, {
        'total_time': total.inSeconds, // Save as seconds
        'updated_at': DateTime.now().toIso8601String(),
      });
    }



    void _showSignOffDialog() {
      setState(() {
        _showSignatureDialog = true;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Digital Sign-off'),
                content: Container(
                  width: double.maxFinite,
                  height: 400,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Please sign below to confirm completion of work order: ${widget.workOrder}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Customer: ${widget.customerName.isNotEmpty ? widget.customerName : widget.assignedTo}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Vehicle: ${widget.vehicle}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Signature:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Signature(
                            controller: _signatureController,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              _signatureController.clear();
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: _isProcessingSignOff
                        ? null
                        : () {
                            _signatureController.clear();
                            Navigator.of(context).pop();
                            setState(() {
                              _showSignatureDialog = false;
                            });
                          },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _isProcessingSignOff
                        ? null
                        : () async {
                            if (_signatureController.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please provide a signature before confirming.',
                                  ),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }

                            setDialogState(() {
                              _isProcessingSignOff = true;
                            });

                            await _processDigitalSignOff();

                            Navigator.of(context).pop();
                            setState(() {
                              _showSignatureDialog = false;
                              _isProcessingSignOff = false;
                            });
                          },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),

                    child: _isProcessingSignOff
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Confirm Sign-off'),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    Future<void> _processDigitalSignOff() async {
    debugPrint('Entered _processDigitalSignOff');
      try {
        final signatureBytes = await _signatureController.toPngBytes();
        if (signatureBytes == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to capture signature. Please try again.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        // Compress signature image using image package
        final decodedImage = img.decodeImage(signatureBytes);
        if (decodedImage == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to process signature image.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
        // Compress to PNG with lower quality (simulate imageQuality)
        final compressedBytes = img.encodePng(decodedImage, level: 6); // level: 0-9, higher is more compressed

        // Save compressed signature as a temporary file
        final tempDir = await getTemporaryDirectory();
        final fileName = 'signature_${widget.workOrder}_${DateTime.now().millisecondsSinceEpoch}.png';
        final tempFile = File(path.join(tempDir.path, fileName));
        await tempFile.writeAsBytes(compressedBytes);

        // Upload to Supabase Storage (Work Order Photos bucket)
        final imageService = ImageService();
        final imageUrl = await imageService.uploadWorkOrderImage(tempFile, widget.workOrder);
        debugPrint('Sign-off: imageUrl to save: $imageUrl');
        debugPrint('Saving customer_signature URL: $imageUrl');

        // Clean up temp file
        await tempFile.delete();

        final provider = context.read<WorkOrdersProvider>();
        // Update work order with sign-off data and signature image URL
        final updateData = {
          'status': 'Signed Off',
          'signed_off_at': DateTime.now().toIso8601String(),
          'customer_signature': imageUrl,
          'updated_at': DateTime.now().toIso8601String(),
        };
        debugPrint('Sign-off: updateData: $updateData');
        final success = await provider.updateWorkOrder(widget.workOrder, updateData);
        debugPrint('Sign-off: update success: $success');

        if (success && mounted) {
          await _fetchWorkOrder();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Work order successfully signed off!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          _signatureController.clear();
        } else if (mounted) {
          final providerError = context.read<WorkOrdersProvider>().error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to complete sign-off ${providerError != null ? ": $providerError" : ''}',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error during sign-off: ${error.toString()}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }

    @override
    void initState() {
      super.initState();
      currentStatusDisplay = _toDisplayStatus(widget.status);
      _isLoadingSignature = true;
      _fetchWorkOrder();
      _loadAssignedParts();
      _notesController.text = widget.description; // Default to description, update if notes available
      if (widget.customerSignature != null && widget.customerSignature!.isNotEmpty) {
        _workOrderImageUrls = widget.customerSignature!.split(',').map((e) => e.trim()).toList();
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
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
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
        final started =
            _partTimers[id] != null && _partTimers[id] != Duration.zero;
        final completed =
            assignedParts.firstWhere(
              (p) => p['id'] == id,
              orElse: () => {},
            )['part_completed_at'] !=
            null;
        return ((started && !paused && !completed) ||
                (started && paused && !completed)) &&
            id != partId;
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
        final started =
            _partTimers[id] != null && _partTimers[id] != Duration.zero;
        final completed =
            assignedParts.firstWhere(
              (p) => p['id'] == id,
              orElse: () => {},
            )['part_completed_at'] !=
            null;
        return ((started && !paused && !completed) ||
                (started && paused && !completed)) &&
            id != partId;
      });
      if (anyActiveOrPaused) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot start another time track while another is active or paused.',
            ),
          ),
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
      await provider.updateWorkOrderPart(partId, {'part_completed_at': now});
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
      // Prevent status changes if already signed off
      if (currentStatusDisplay == 'Signed Off') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot change status of a signed-off work order.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Prevent marking as Completed if no assigned parts
      if (newStatus == 'Completed') {
        if (assignedParts.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot mark as Completed: No assigned parts for this work order.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        final unfinishedParts = assignedParts.where((part) => part['part_completed_at'] == null).toList();
        if (unfinishedParts.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('All assigned parts must be finished before marking job as Completed.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
      }

      // Job must be complete first before signed off
      if (newStatus == 'Signed Off') {
        if (currentStatusDisplay != 'Completed') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Work order must be completed before it can be signed off.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        _showSignOffDialog();
        return;
      }

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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to update status${providerError != null ? ": $providerError" : ''}',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Job status updated to $newStatus'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (error) {
        setState(() {
          isUpdating = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update status: ${error.toString()}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
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
        final parts = await provider.getAssignedPartsForWorkOrder(
          widget.workOrder,
        );

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
    Future<void> _captureAndUploadPhoto() async {
      try {
        final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
        if (image == null) return;
        if (!_isUploadingPhoto) {
          setState(() { _isUploadingPhoto = true; });
        }
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
        try {
          final imageFile = File(image.path);
          final imageService = ImageService();
          final imageUrl = await imageService.uploadWorkOrderImage(imageFile, widget.workOrder);
          // Update WorkOrders.image_url (append to list)
          final provider = context.read<WorkOrdersProvider>();
          List<String> updatedUrls = List<String>.from(_workOrderImageUrls);
          updatedUrls.add(imageUrl);
          await provider.updateWorkOrder(widget.workOrder, {
            'image_url': updatedUrls,
            'updated_at': DateTime.now().toIso8601String(),
          });
          setState(() {
            _workOrderImageUrls = updatedUrls;
          });
    Future<void> _deleteWorkOrderImage(int idx) async {
      final provider = context.read<WorkOrdersProvider>();
      final imageUrl = _workOrderImageUrls[idx];
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      try {
        final imageService = ImageService();
        await imageService.deleteImage(imageUrl, 'WorkOrder');
        List<String> updatedUrls = List<String>.from(_workOrderImageUrls);
        updatedUrls.removeAt(idx);
        await provider.updateWorkOrder(widget.workOrder, {
          'image_url': updatedUrls,
          'updated_at': DateTime.now().toIso8601String(),
        });
        setState(() {
          _workOrderImageUrls = updatedUrls;
        });
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo deleted successfully'), backgroundColor: Colors.green),
        );
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete photo: $e'), backgroundColor: Colors.red),
        );
      }
    }
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo uploaded successfully'), backgroundColor: Colors.green),
          );
        } catch (e) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload photo: $e'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        // Detect cameraDelegate error and show user-friendly message
        final errorMsg = e.toString();
        if (errorMsg.contains('cameraDelegate')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera is not available on this platform or not configured. Please check your setup.'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error capturing photo: $errorMsg'), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() { _isUploadingPhoto = false; });
      }
    }
    Widget _buildInfoRow(IconData icon, String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
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

    Widget _buildStatusButton(
      String text,
      Color color,
      bool isSelected,
      VoidCallback? onTap,
    ) {
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

    String _getTotalTimeSummary() {
      Duration total = Duration.zero;
      for (final part in assignedParts) {
        final startedAt = part['part_started_at'];
        final completedAt = part['part_completed_at'];
        if (startedAt != null && completedAt != null) {
          final start = DateTime.parse(startedAt);
          final end = DateTime.parse(completedAt);
          final diff =
              end.difference(start) - Duration(hours: 8); // Subtract 8 hours
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
    debugPrint('[BUILD] JobDetailsScreen build:');
    debugPrint('  _customerSignature=$_customerSignature');
    debugPrint('  currentStatusDisplay=$currentStatusDisplay');
    debugPrint('  widget.workOrder=${widget.workOrder}');
    debugPrint('  widget.customerSignature=${widget.customerSignature}');
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface,
            ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
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
                    // Photo capture and display section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Work Order Photos:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Capture Photo'),
                              onPressed: _isUploadingPhoto ? null : _captureAndUploadPhoto,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: _workOrderImageUrls.isEmpty
                              ? Center(child: Text('No photos uploaded.'))
                              : ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _workOrderImageUrls.length,
                                  separatorBuilder: (context, idx) => const SizedBox(width: 8),
                                  itemBuilder: (context, idx) {
                                    final url = _workOrderImageUrls[idx];
                                    return Stack(
                                      children: [
                                        Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            color: Colors.green[100],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              url,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Icon(Icons.broken_image, size: 32, color: Colors.grey);
                                              },
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return const Center(child: CircularProgressIndicator());
                                              },
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () => _deleteWorkOrderImage(idx),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(0.8),
                                                shape: BoxShape.circle,
                                              ),
                                              padding: const EdgeInsets.all(4),
                                              child: const Icon(Icons.delete, color: Colors.white, size: 20),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 16),
                        if (currentStatusDisplay == 'Signed Off')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Customer Signature:', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Container(
                                width: 220,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _isLoadingSignature
                                      ? const Center(child: CircularProgressIndicator())
                                      : (_customerSignature != null && _customerSignature!.isNotEmpty
                                          ? Image.network(
                                              _customerSignature!,
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Icon(Icons.edit, size: 32, color: Colors.grey); // Fallback
                                              },
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return const Center(child: CircularProgressIndicator());
                                              },
                                            )
                                          : Icon(Icons.edit, size: 32, color: Colors.grey)),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                      ],
                    ),
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
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Internal Notes:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      enabled: currentStatusDisplay != 'Signed Off',
                      decoration: InputDecoration(
                        hintText: 'Add notes for this work order...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.save),
                          label: Text(
                            _isSavingNotes ? 'Saving...' : 'Save Notes',
                          ),
                          onPressed: (_isSavingNotes || currentStatusDisplay == 'Signed Off') ? null : _updateNotes,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (currentStatusDisplay == 'Signed Off')
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Notes cannot be edited after sign-off.',
                          style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
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
                    _buildInfoRow(
                      Icons.person,
                      widget.customerName.isNotEmpty
                          ? widget.customerName
                          : widget.assignedTo,
                    ),
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
                          _buildInfoRow(
                            Icons.confirmation_number,
                            'VIN: ${widget.vehicleVin.isNotEmpty ? widget.vehicleVin : 'N/A'}',
                          ),
                          _buildInfoRow(
                            Icons.credit_card,
                            'License Plate: ${widget.licensePlate}',
                          ),
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
                      Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text(
                              'Updating status...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatusButton(
                                  'Pending',
                                  Colors.orange,
                                  currentStatusDisplay == 'Pending',
                                  () => updateJobStatus('Pending'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatusButton(
                                  'Accepted',
                                  Colors.blue,
                                  currentStatusDisplay == 'Accepted',
                                  () => updateJobStatus('Accepted'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatusButton(
                                  'In Progress',
                                  Colors.green,
                                  currentStatusDisplay == 'In Progress',
                                  () => updateJobStatus('In Progress'),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildStatusButton(
                                    'On Hold',
                                    Colors.red,
                                    currentStatusDisplay == 'On Hold',
                                    () => updateJobStatus('On Hold'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatusButton(
                                    'Completed',
                                    Colors.purple,
                                    currentStatusDisplay == 'Completed',
                                    () => updateJobStatus('Completed'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatusButton(
                                    'Signed Off',
                                    Colors.grey,
                                    currentStatusDisplay == 'Signed Off',
                                    currentStatusDisplay == 'Completed'
                                        ? () => updateJobStatus('Signed Off')
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                          if (currentStatusDisplay == 'Completed') ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Ready for digital sign-off, click "Signed Off" to begin the signature process.',
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          // Show message if no assigned parts
                          if (assignedParts.isEmpty && currentStatusDisplay != 'Completed' && currentStatusDisplay != 'Signed Off') ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'No assigned parts for this work order. You cannot mark it as Completed.',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          // Show message if not all parts are completed and status is not Completed or Signed Off
                          if (assignedParts.where((part) => part['part_completed_at'] == null).isNotEmpty && assignedParts.isNotEmpty && currentStatusDisplay != 'Completed' && currentStatusDisplay != 'Signed Off') ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'All assigned parts must be completed before you can mark this job as Completed.',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                      Center(child: CircularProgressIndicator())
                    else if (assignedParts
                        .where((part) => part['part_completed_at'] == null)
                        .isEmpty)
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
                      ...assignedParts
                          .where((part) => part['part_completed_at'] == null)
                          .map((part) {
                            final partId = part['id'];
                            final partName = part['Parts'] != null
                                ? part['Parts']['name']
                                : part['name'] ?? 'N/A';
                            final partCategory = part['Parts'] != null
                                ? part['Parts']['category']
                                : part['category'] ?? 'N/A';
                            final partPrice = part['Parts'] != null
                                ? part['Parts']['unit_price']
                                : part['unit_price'] ?? 0;
                            final quantity = part['quantity'] ?? 0;
                            final totalPrice =
                                part['total_price'] ?? (partPrice * quantity);
                            final notes = part['notes'] ?? '';
                            final startedAt = part['part_started_at'];
                            final completedAt = part['part_completed_at'];
                            final isStarted = startedAt != null;
                            final isCompleted = completedAt != null;
                            final isPaused = _partPaused[partId] == true;
                            final timerValue =
                                _partTimers[partId] ?? Duration.zero;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceVariant,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              partName ?? 'N/A',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Category: $partCategory',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.7),
                                                fontSize: 12,
                                              ),
                                            ),
                                            if (notes.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'Notes: $notes',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.7),
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Qty: $quantity',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.7),
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            FutureBuilder<String>(
                                              future: CurrencyFormatter.formatWithAutoConversion(partPrice ?? 0),
                                              builder: (context, snapshot) {
                                                return Text(
                                                  'Unit: ${snapshot.data ?? '\$${(partPrice ?? 0).toStringAsFixed(2)}'}',
                                                  style: TextStyle(
                                                    color: Colors.green[700],
                                                    fontSize: 12,
                                                  ),
                                                );
                                              },
                                            ),
                                            const SizedBox(height: 4),
                                            FutureBuilder<String>(
                                              future: CurrencyFormatter.formatWithAutoConversion(totalPrice ?? 0),
                                              builder: (context, snapshot) {
                                                return Text(
                                                  'Total: ${snapshot.data ?? '\$${(totalPrice ?? 0).toStringAsFixed(2)}'}',
                                                  style: TextStyle(
                                                    color: Colors.green[900],
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                );
                                              },
                                            ),
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
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12,
                                            ),
                                          ),
                                          icon: const Icon(Icons.pause),
                                          label: const Text('Pause'),
                                          onPressed: () {
                                            _pauseTimer(partId);
                                          },
                                        ),
                                      ],
                                    ),
                                  ] else if (isStarted &&
                                      !isCompleted &&
                                      isPaused) ...[
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
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 24,
                                                vertical: 12,
                                              ),
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
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12,
                                            ),
                                          ),
                                          icon: const Icon(Icons.check),
                                          label: const Text('Complete'),
                                          onPressed: () {
                                            _completeTimer(partId, part);
                                          },
                                        ),
                                      ],
                                    ),
                                  ] else if (!isStarted) ...[
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
                          })
                          .toList(),
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
                    if (assignedParts
                        .where((part) => part['part_completed_at'] != null)
                        .isEmpty)
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
                          final finishedParts = assignedParts.where(
                            (part) => part['part_completed_at'] != null,
                          );
                          double totalSum = 0;
                          for (final part in finishedParts) {
                            final partPrice = part['Parts'] != null
                                ? part['Parts']['unit_price']
                                : part['unit_price'] ?? 0;
                            final quantity = part['quantity'] ?? 0;
                            final totalPrice =
                                part['total_price'] ?? (partPrice * quantity);
                            totalSum += (totalPrice is num
                                ? totalPrice.toDouble()
                                : 0);
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: FutureBuilder<String>(
                              future: CurrencyFormatter.formatWithAutoConversion(totalSum),
                              builder: (context, snapshot) {
                                return Text(
                                  'Total Price of Finished Parts: ${snapshot.data ?? '\$${totalSum.toStringAsFixed(2)}'}',
                                  style: TextStyle(
                                    color: Colors.green[900],
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      ...assignedParts
                          .where((part) => part['part_completed_at'] != null)
                          .map((part) {
                            final partName = part['Parts'] != null
                                ? part['Parts']['name']
                                : part['name'] ?? 'N/A';
                            final partCategory = part['Parts'] != null
                                ? part['Parts']['category']
                                : part['category'] ?? 'N/A';
                            final partPrice = part['Parts'] != null
                                ? part['Parts']['unit_price']
                                : part['unit_price'] ?? 0;
                            final quantity = part['quantity'] ?? 0;
                            final totalPrice =
                                part['total_price'] ?? (partPrice * quantity);
                            final notes = part['notes'] ?? '';
                            final completedAt = part['part_completed_at'];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceVariant,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          partName ?? 'N/A',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Category: $partCategory',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.7),
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (notes.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Notes: $notes',
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.7),
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Qty: $quantity',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        FutureBuilder<String>(
                                          future: CurrencyFormatter.formatWithAutoConversion(partPrice ?? 0),
                                          builder: (context, snapshot) {
                                            return Text(
                                              'Unit: ${snapshot.data ?? '\$${(partPrice ?? 0).toStringAsFixed(2)}'}',
                                              style: TextStyle(
                                                color: Colors.green[700],
                                                fontSize: 12,
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 4),
                                        FutureBuilder<String>(
                                          future: CurrencyFormatter.formatWithAutoConversion(totalPrice ?? 0),
                                          builder: (context, snapshot) {
                                            return Text(
                                              'Total: ${snapshot.data ?? '\$${(totalPrice ?? 0).toStringAsFixed(2)}'}',
                                              style: TextStyle(
                                                color: Colors.green[900],
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Completed: ' +
                                              (completedAt != null
                                                  ? _formatCompletedDate(
                                                      completedAt,
                                                    )
                                                  : ''),
                                          style: TextStyle(
                                            color: Colors.green[900],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                          .toList(),
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                        final partName = part['Parts'] != null
                            ? part['Parts']['name']
                            : part['name'] ?? 'N/A';
                        final completedAt = part['part_completed_at'];
                        final startedAt = part['part_started_at'];
                        Duration duration = Duration.zero;
                        if (startedAt != null && completedAt != null) {
                          final start = DateTime.parse(startedAt);
                          final end = DateTime.parse(completedAt);
                          duration =
                              end.difference(start) -
                              Duration(hours: 8); // Subtract 8 hours
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
                                    Text(
                                      partName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (completedAt != null && startedAt != null)
                                      Text(
                                        '${hours}h ${minutes}m ${seconds}s',
                                        style: TextStyle(color: Colors.green),
                                      ),
                                  ],
                                ),
                              ),
                              if (completedAt != null && startedAt != null)
                                Text(
                                  '${hours}h ${minutes}m ${seconds}s',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
                            style: const TextStyle(
                              fontSize: 18,

                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
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
