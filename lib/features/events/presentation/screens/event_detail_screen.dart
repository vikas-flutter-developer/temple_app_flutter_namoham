import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../data/models/event_model.dart';
import '../providers/events_provider.dart';



import 'create_event_screen.dart'; // Ensure this matches path

class EventDetailScreen extends StatefulWidget {
  final EventModel event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }
  
  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final provider = Provider.of<EventsProvider>(context, listen: false);
    
    // Verify Payment on Backend
    final verified = await provider.verifyPayment(
      razorpayOrderId: response.orderId ?? '',
      razorpayPaymentId: response.paymentId ?? '',
      razorpaySignature: response.signature ?? '',
    );

    if (!mounted) return;

    if (verified) {
      // Payment successful - complete registration
      final success = await provider.completeEventRegistration(widget.event.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Payment successful! You are registered for ${widget.event.eventName}'
                : 'Payment successful but registration failed. Please contact support.'),
            backgroundColor: success ? Colors.green : Colors.orange,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment verification failed. Please contact support.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('External wallet selected: ${response.walletName}')),
      );
    }
  }

  Future<void> _initiatePayment(double price) async {
    final provider = Provider.of<EventsProvider>(context, listen: false);
    
    // Create Order on Backend
    final order = await provider.createPaymentOrder(
      amount: price,
      eventId: widget.event.id,
      description: 'Registration for ${widget.event.eventName}',
      recipientId: widget.event.organizerId,
      recipientType: widget.event.organizerType,
    );

    if (!mounted) return;

    if (order == null || !order.containsKey('id')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to create payment order. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String orderId = order['id'];

    // Open Razorpay checkout with Order ID
    final options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag', // Replace with your Razorpay key from .env
      'amount': (price * 100).toInt(), // Amount in paise
      'name': widget.event.organizerName,
      'description': 'Registration for ${widget.event.eventName}',
      'order_id': orderId,
      'prefill': {
        'contact': '',
        'email': '',
      },
      'theme': {
        'color': '#FF6B35',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteEvent(BuildContext context, EventModel event, EventsProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await provider.deleteEvent(event.id);
      if (mounted) {
        if (success) {
           Navigator.pop(context); // Close detail screen
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event deleted successfully')));
        } else {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? 'Failed to delete event')));
        }
      }
    }
  }

  Future<void> _editEvent(BuildContext context, EventModel event) async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateEventScreen(
            organizerId: event.organizerId,
            organizerType: event.organizerType,
            event: event,
          ),
        ),
      );

      if (result == true && mounted) {
        // Event updated, but this screen holds old data in `widget.event`.
        // Simplest way to refresh is to pop back to list.
        Navigator.pop(context); 
      }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = widget.event;

    // ... existing dateText, locationParts setup ...
    final dateText = event.eventDate != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(event.eventDate!.toLocal())
        : 'Date & time TBD';

    final locationParts = <String>[
      if (event.location.trim().isNotEmpty) event.location.trim(),
      if (event.address.trim().isNotEmpty) event.address.trim(),
      if (event.city.trim().isNotEmpty) event.city.trim(),
      if (event.state.trim().isNotEmpty) event.state.trim(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          Consumer<EventsProvider>(
            builder: (context, provider, child) {
              if (provider.isOrganizer(event)) {
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editEvent(context, event),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteEvent(context, event, provider),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    // ... rest of body
      body: Consumer<EventsProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    backgroundImage: event.organizerImage.trim().isNotEmpty
                        ? NetworkImage(event.organizerImage)
                        : null,
                    child: event.organizerImage.trim().isEmpty
                        ? Text(
                            event.organizerName.isNotEmpty
                                ? event.organizerName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.organizerName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          event.organizerType,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),

              Text(
                event.eventName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                dateText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (event.eventTime.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Time: ${event.eventTime}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              _InfoTile(
                icon: Icons.location_on_outlined,
                title: 'Location',
                subtitle: locationParts.isNotEmpty
                    ? locationParts.join(', ')
                    : 'Not specified',
              ),
              _InfoTile(
                icon: Icons.people_outline,
                title: 'Capacity',
                subtitle: '${event.registeredCount}/${event.capacity}',
              ),
              _InfoTile(
                icon: Icons.category_outlined,
                title: 'Type',
                subtitle: event.eventType.isNotEmpty ? event.eventType : 'other',
              ),
              _InfoTile(
                icon: Icons.payments_outlined,
                title: 'Price',
                subtitle: event.isFree ? 'FREE' : '₹${event.price}',
              ),

              const SizedBox(height: 16),
              Text(
                'Description',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event.description.isNotEmpty
                    ? event.description
                    : 'No description provided.',
                style: theme.textTheme.bodyMedium,
              ),

              const SizedBox(height: 24),

              if (provider.error != null) ...[
                Text(
                  provider.error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],

              if (provider.canAttendEvent && !provider.isOrganizer(event))
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.isLoading || !event.isActive || event.isFull
                        ? null
                        : () async {
                            final price = await provider.attendEvent(event);
                            
                            if (context.mounted) {
                              if (price == null) {
                                // Registration successful (free event)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Registered for event successfully!')),
                                );
                              } else if (price > 0) {
                                // Paid event - initiate Razorpay payment
                                await _initiatePayment(price);
                              } else if (provider.error != null) {
                                // Error occurred
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(provider.error!)),
                                );
                              }
                            }
                          },
                    child: Text(
                      !event.isActive
                          ? 'Event inactive'
                          : event.isFull
                              ? 'Event full'
                              : event.isFree
                                  ? 'Attend Event (Free)'
                                  : 'Attend Event - ₹${event.price}',
                    ),
                  ),
                )
              else if (provider.isOrganizer(event))
                Text(
                  'You are the organizer of this event.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Text(
                  'Only users and creators can attend events.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
    );
  }
}
