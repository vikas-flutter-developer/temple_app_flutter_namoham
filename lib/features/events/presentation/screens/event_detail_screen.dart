import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/event_model.dart';
import '../providers/events_provider.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel event;
  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
      ),
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

              if (provider.canAttendEvent)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.isLoading || !event.isActive || event.isFull
                        ? null
                        : () async {
                            final ok = await provider.attendEvent(event.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok
                                      ? 'Registered for event'
                                      : (provider.error ?? 'Failed to register')),
                                ),
                              );
                            }
                          },
                    child: Text(
                      !event.isActive
                          ? 'Event inactive'
                          : event.isFull
                              ? 'Event full'
                              : 'Attend Event',
                    ),
                  ),
                )
              else
                Text(
                  'Only users can attend events.',
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
