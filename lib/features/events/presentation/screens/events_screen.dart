import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_service.dart';
import '../providers/events_provider.dart';
import 'event_detail_screen.dart';
import 'create_event_screen.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService.create();

    return ChangeNotifierProvider(
      create: (_) => EventsProvider(apiService)..fetchEvents(),
      child: const _EventsView(),
    );
  }
}

class _EventsView extends StatelessWidget {
  const _EventsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Consumer<EventsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.events.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${provider.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => provider.fetchEvents(),
                      child: const Text('Retry'),
                    )
                  ],
                ),
              ),
            );
          }

          if (provider.events.isEmpty) {
            return const Center(child: Text('No events available'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchEvents(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: provider.events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final event = provider.events[index];

                final dateText = event.eventDate != null
                    ? DateFormat('dd MMM yyyy').format(event.eventDate!.toLocal())
                    : 'Date TBD';

                final timeText = event.eventTime.isNotEmpty ? event.eventTime : 'Time TBD';

                return InkWell(
                  onTap: () {
                    // EventsProvider is scoped to this route, so pass it to the next route.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: provider,
                          child: EventDetailScreen(event: event),
                        ),
                      ),
                    );
                  },
                  child: Card(
                    color: theme.colorScheme.surfaceContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
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
                                  event.eventName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$dateText • $timeText',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  event.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  event.isFree ? 'FREE' : '₹${event.price}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${event.registeredCount}/${event.capacity}',
                                style: theme.textTheme.bodySmall,
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Consumer<EventsProvider>(
        builder: (context, provider, child) {
          if (!provider.canCreateEvent) return const SizedBox.shrink();

          return FloatingActionButton(
            onPressed: () {
              // EventsProvider is scoped to this route, so pass it to the next route.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: provider,
                    child: const CreateEventScreen(),
                  ),
                ),
              );
            },
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}
