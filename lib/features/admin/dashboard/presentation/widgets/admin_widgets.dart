import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_user_app/features/admin/dashboard/data/models/dashboard_models.dart';



class AdminHeader extends StatelessWidget {
  final String title;
  final bool showSearch;
  final Widget? filters;
  final VoidCallback? onBackPressed;
  final ValueChanged<String>? onSearchChanged;

  // Date filter inputs
  final String selectedFilterLabel;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<String>? onFilterSelected;
  final ValueChanged<DateTime?>? onStartDateSelected;
  final ValueChanged<DateTime?>? onEndDateSelected;

  const AdminHeader({
    super.key,
    this.title = "",
    this.showSearch = true,
    this.filters,
    this.onBackPressed,
    this.onSearchChanged,
    this.selectedFilterLabel = "All Time",
    this.startDate,
    this.endDate,
    this.onFilterSelected,
    this.onStartDateSelected,
    this.onEndDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBackPressed ?? () => Navigator.maybePop(context),
                child: const Icon(Icons.arrow_back, color: Colors.black),
              ),
              const SizedBox(width: 16),
              if (title.isNotEmpty) ...[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 24),
              ],
              if (showSearch)
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                         Expanded(child: TextField(
                          onChanged: onSearchChanged,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Colors.white,
                            hintText: "Search",
                            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                            contentPadding: const EdgeInsets.only(bottom: 14),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              if (showSearch) const SizedBox(width: 24),
              if (filters != null) filters!,
            ],
          ),
          const SizedBox(height: 24),
           Row(
            children: [
              _buildFilterDropdown(context),
              const SizedBox(width: 24),
              _buildStartDatePicker(context),
              const SizedBox(width: 24),
              _buildEndDatePicker(context),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(BuildContext context) {
    final items = [
      const PopupMenuItem(value: 'all', child: Text("All Time")),
      const PopupMenuItem(value: 'today', child: Text("Today")),
      const PopupMenuItem(value: 'yesterday', child: Text("Yesterday")),
      const PopupMenuItem(value: 'this_week', child: Text("This Week")),
      const PopupMenuItem(value: 'this_month', child: Text("This Month")),
    ];

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (onFilterSelected != null) {
          onFilterSelected!(value);
        }
      },
      itemBuilder: (context) => items,
      child: Row(
        children: [
          Text(
            selectedFilterLabel,
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800], fontSize: 14),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildStartDatePicker(BuildContext context) {
    final dateText = startDate != null 
        ? "${startDate!.month}/${startDate!.day}/${startDate!.year}"
        : "Start Date";

    return GestureDetector(
      onTap: () async {
        if (onStartDateSelected != null) {
          final selectedDate = await showDatePicker(
            context: context,
            initialDate: startDate ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (selectedDate != null) {
            onStartDateSelected!(selectedDate);
          }
        }
      },
      child: Row(
        children: [
          Text(
            dateText,
            style: TextStyle(
              fontWeight: FontWeight.w600, 
              color: startDate != null ? const Color(0xFF00A3FF) : Colors.grey[800], 
              fontSize: 14,
            ),
          ),
          if (startDate != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                if (onStartDateSelected != null) onStartDateSelected!(null);
              },
              child: const Icon(Icons.clear, size: 16, color: Colors.red),
            ),
          ] else ...[
            const SizedBox(width: 6),
            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
          ],
        ],
      ),
    );
  }

  Widget _buildEndDatePicker(BuildContext context) {
    final dateText = endDate != null 
        ? "${endDate!.month}/${endDate!.day}/${endDate!.year}"
        : "End Date";

    return GestureDetector(
      onTap: () async {
        if (onEndDateSelected != null) {
          final selectedDate = await showDatePicker(
            context: context,
            initialDate: endDate ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (selectedDate != null) {
            onEndDateSelected!(selectedDate);
          }
        }
      },
      child: Row(
        children: [
          Text(
            dateText,
            style: TextStyle(
              fontWeight: FontWeight.w600, 
              color: endDate != null ? const Color(0xFF00A3FF) : Colors.grey[800], 
              fontSize: 14,
            ),
          ),
          if (endDate != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                if (onEndDateSelected != null) onEndDateSelected!(null);
              },
              child: const Icon(Icons.clear, size: 16, color: Colors.red),
            ),
          ] else ...[
            const SizedBox(width: 6),
            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
          ],
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final Widget? graph; // For the bar chart visualization

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.iconColor = Colors.blue,
    this.iconBgColor = const Color(0xFFE3F2FD),
    this.graph,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (icon != null) ...[
              CircleAvatar(
                radius: 28,
                backgroundColor: iconBgColor,
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                ],
              ),
            ),
            if (graph != null) ...[
              const SizedBox(width: 16),
              graph!,
            ]
          ],
        ),
      ),
    );
  }
}

class AdminTable extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;
  final ValueChanged<int>? onRowTap;
  final List<int>? flexes;

  const AdminTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.flexes,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFlexes = (flexes != null && flexes!.length == columns.length)
        ? flexes!
        : List<int>.filled(columns.length, 1);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Header
          Row(
            children: [
              for (int i = 0; i < columns.length; i++)
                Expanded(
                  flex: effectiveFlexes[i],
                  child: Text(
                    columns[i],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 32),
          // Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 32),
            itemBuilder: (context, index) {
              final rowContent = Row(
                children: [
                  for (int i = 0; i < rows[index].length; i++)
                    Expanded(
                      flex: i < effectiveFlexes.length ? effectiveFlexes[i] : 1,
                      child: rows[index][i],
                    ),
                ],
              );

              if (onRowTap != null) {
                return InkWell(
                  onTap: () => onRowTap!(index),
                  hoverColor: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                    child: rowContent,
                  ),
                );
              }

              return rowContent;
            },
          ),
        ],
      ),
    );
  }
}

class ClientDetailsDialog extends StatelessWidget {
  final ClientModel client;

  const ClientDetailsDialog({super.key, required this.client});

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'user':
        return Colors.teal;
      case 'temple':
        return Colors.orange;
      case 'creator':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(client.type);
    final isOnline = client.status.toLowerCase() == 'online';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      backgroundColor: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Close and Profile Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    client.type.toUpperCase(),
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Profile image, name and status
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: typeColor.withOpacity(0.2),
                    backgroundImage: (client.image != null && client.image!.isNotEmpty)
                        ? NetworkImage(client.image!)
                        : null,
                    child: (client.image == null || client.image!.isEmpty)
                        ? Text(
                            client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                            style: TextStyle(color: typeColor, fontSize: 32, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    client.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        client.status,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            
            // Details List
            _buildDetailItem(context, Icons.perm_identity, "ACCOUNT ID", client.userId, canCopy: true),
            _buildDetailItem(context, Icons.email_outlined, "EMAIL ADDRESS", client.email, canCopy: true),
            _buildDetailItem(context, Icons.phone_outlined, "PHONE NUMBER", client.phone, canCopy: true),
            _buildDetailItem(context, Icons.wc_outlined, "GENDER", client.gender ?? 'N/A'),
            _buildDetailItem(
              context, 
              Icons.cake_outlined, 
              client.type.toLowerCase() == 'temple' ? "ESTABLISHMENT DATE" : "DATE OF BIRTH", 
              _formatDateString(client.dateOfBirth)
            ),
            _buildDetailItem(context, Icons.location_on_outlined, "LOCATION", client.location),
            if (client.createdAt != null)
              _buildDetailItem(context, Icons.calendar_today_outlined, "JOINED DATE", _formatDateTime(client.createdAt!)),
              
            const SizedBox(height: 16),
            
            // Bottom Action (Close)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A3FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, IconData icon, String label, String value, {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[400], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (canCopy && value.isNotEmpty && value != 'N/A')
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              color: Colors.grey[400],
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 18,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$label copied to clipboard!'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return "${dt.month}/${dt.day}/${dt.year}";
  }

  String _formatDateString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == 'N/A') return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.day}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
