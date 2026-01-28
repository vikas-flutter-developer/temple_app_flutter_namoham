import 'package:flutter/material.dart';

class ReviewDropDownWidget extends StatefulWidget {
  const ReviewDropDownWidget({super.key});

  @override
  State<ReviewDropDownWidget> createState() => _ReviewDropDownWidgetState();
}

class _ReviewDropDownWidgetState extends State<ReviewDropDownWidget> {
  String _selectedFilterType = 'Newest';
  final List<String> _filterTypes = [
    'Newest',
    'Oldest',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      //width: 118,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(30),
      ),
      child: DropdownButton<String>(
        value: _selectedFilterType,
        borderRadius: BorderRadius.circular(10),
        dropdownColor: theme.colorScheme.surfaceContainerHighest,
        icon: const Icon(Icons.keyboard_arrow_down),
        //elevation: 16,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
        underline: Container(
          height: 0,
        ),
        onChanged: (String? value) {
          setState(() {
            _selectedFilterType = value!;
            print('Filter changed to: $_selectedFilterType');
          });
        },
        items: _filterTypes.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }
}
