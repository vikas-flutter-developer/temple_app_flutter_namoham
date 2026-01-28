import 'package:flutter/material.dart';

class CustomDropdown extends StatefulWidget {
  final String title;
  final List<String> items;
  final String? value;
  final Function(String?)? onChanged;

  const CustomDropdown({
    super.key,
    required this.title,
    required this.items,
    this.value,
    required this.onChanged,
  });

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      
      value: widget.value,
      decoration: InputDecoration(
        labelText: widget.title,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
      ),
      items: widget.items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: widget.onChanged,
    );
  }
}
