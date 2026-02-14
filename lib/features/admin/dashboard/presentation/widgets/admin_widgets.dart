import 'package:flutter/material.dart';



class AdminHeader extends StatelessWidget {
  final String title;
  final bool showSearch;
  final Widget? filters;
  final VoidCallback? onBackPressed;
  final ValueChanged<String>? onSearchChanged;

  const AdminHeader({
    super.key,
    this.title = "",
    this.showSearch = true,
    this.filters,
    this.onBackPressed,
    this.onSearchChanged,
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
              _buildDropdown("Today"),
              const SizedBox(width: 24),
              _buildDropdown("Start Date"),
              const SizedBox(width: 24),
              _buildDropdown("End Date"),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDropdown(String text) {
    List<PopupMenuEntry<String>> items = [];
    if (text == "Today") {
      items = [
        const PopupMenuItem(value: 'today', child: Text("Today")),
        const PopupMenuItem(value: 'yesterday', child: Text("Yesterday")),
        const PopupMenuItem(value: 'this_week', child: Text("This Week")),
        const PopupMenuItem(value: 'this_month', child: Text("This Month")),
      ];
    } else if (text == "Start Date" || text == "End Date") {
      items = [
        const PopupMenuItem(value: 'select', child: Text("Select Date")),
        const PopupMenuItem(value: 'clear', child: Text("Clear")),
      ];
    }

    return PopupMenuButton<String>(
      onSelected: (value) {
        // Implement date filtering action here
        // If 'select', we could showDatePicker in a real implementation
      },
      itemBuilder: (context) => items,
      child: Row(
        children: [
          Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800], fontSize: 14)),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey),
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

  const AdminTable({
    super.key,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
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
              for (var col in columns)
                Expanded(child: Text(col, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[400], fontSize: 11))),
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
              return Row(
                children: [
                  for (var widget in rows[index])
                    Expanded(child: widget),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
