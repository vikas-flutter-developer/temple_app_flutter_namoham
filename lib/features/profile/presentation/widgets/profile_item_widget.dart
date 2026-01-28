import 'package:flutter/material.dart';

class ProfileItemsWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Function()? onTap;

  const ProfileItemsWidget({super.key, required this.icon, required this.title, required this.subtitle, this.onTap});

  @override
  State<ProfileItemsWidget> createState() => _ProfileItemsWidgetState();
}

class _ProfileItemsWidgetState extends State<ProfileItemsWidget> {
  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(widget.icon, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}