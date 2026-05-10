import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../controllers/booking_controller.dart';
import '../../../controllers/session_controller.dart';
import '../../../models/session_model.dart';
import '../../widgets/flex_app_bar.dart';

class SessionAttendeesScreen extends StatefulWidget {
  final String sessionId;
  final String? backTarget;

  const SessionAttendeesScreen({
    required this.sessionId,
    this.backTarget,
    super.key,
  });

  @override
  State<SessionAttendeesScreen> createState() => _SessionAttendeesScreenState();
}

class _SessionAttendeesScreenState extends State<SessionAttendeesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        final sessionController = context.read<SessionController>();
        if (sessionController.sessions.isEmpty) {
          sessionController.fetchAllSessions();
        }
        context
            .read<BookingController>()
            .fetchSessionBookingsWithMembers(widget.sessionId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionController = context.watch<SessionController>();
    SessionModel? session;
    for (final item in sessionController.sessions) {
      if (item.id == widget.sessionId) {
        session = item;
        break;
      }
    }

    return Scaffold(
      appBar: FlexAppBar(
        title: 'Session Attendees',
        backTarget: widget.backTarget ?? '/coach/home',
      ),
      body: Consumer<BookingController>(
        builder: (context, bookingController, _) {
          if (bookingController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (bookingController.error != null) {
            return Center(
              child: Text(
                'Error: ${bookingController.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final attendees = bookingController.sessionBookings;

          if (attendees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No confirmed bookings yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (session != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${DateFormat('MMM dd, yyyy').format(session.startAt)} • ${DateFormat('HH:mm').format(session.startAt)} - ${DateFormat('HH:mm').format(session.endAt)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${attendees.length} Confirmed Bookings',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    'Attendees (${attendees.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: attendees.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final attendee = attendees[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      attendee.memberName.isNotEmpty
                                          ? attendee.memberName[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        attendee.memberName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (attendee.memberEmail.isNotEmpty)
                                        Text(
                                          attendee.memberEmail,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getPaymentStatusColor(
                                            attendee.paymentStatus)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    attendee.paymentStatus
                                        .toUpperCase()
                                        .replaceAll('_', ' '),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _getPaymentStatusColor(
                                          attendee.paymentStatus),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 52.0),
                              child: Text(
                                'Booked: ${_formatDate(attendee.bookedAt)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                            if (attendee.paidAmountTnd > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 52.0),
                                child: Text(
                                  'Amount: ${attendee.paidAmountTnd.toStringAsFixed(2)} TND',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
