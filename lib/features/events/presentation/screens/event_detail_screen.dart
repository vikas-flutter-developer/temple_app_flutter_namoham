import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
      eventId: widget.event.id,
    );

    if (!mounted) return;

    if (verified) {
      // Payment successful and verified
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful! You are registered for ${widget.event.eventName}'),
            backgroundColor: Colors.green,
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
    
    // Create Payment Link
    final result = await provider.createPaymentLink(widget.event.id);

    if (!mounted) return;

    if (result == null || !result.containsKey('paymentLink')) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to create payment link.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String url = result['paymentLink'];

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      // We can't auto-verify with link easily without deep links. 
      // For now, user returns and we might need a "Verify Payment" button or auto-refresh.
      // But let's stick to the flow: User pays -> Back to App -> Maybe manual refresh?
      // Or we can rely on Webhooks (backend side). 
      // For this step, just opening the link.
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch payment link')),
      );
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

                            final result = await provider.attendEvent(event);
                            
                            if (context.mounted) {
                              if (result.containsKey('success') && result['success'] == true) {
                                // Registration successful (free event)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Registered for event successfully!')),
                                );
                              } else if (result.containsKey('isPaid') && result['isPaid'] == true) {
                                // Paid event - initiate Razorpay payment
                                double price = 0;
                                if (result['price'] is int) {
                                   price = (result['price'] as int).toDouble();
                                } else if (result['price'] is double) {
                                   price = result['price'];
                                }
                                await _initiatePayment(price);
                              } else if (result.containsKey('message') && result['success'] == false) {
                                // Explicit failure (do nothing as provider.error is set, but prevent success msg)
                                // Only show snackbar if not already shown via provider updates or needed
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
