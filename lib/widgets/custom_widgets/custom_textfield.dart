import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CustomTextField extends StatefulWidget {
  final String labelText;
  final TextEditingController controller;
  final bool obscure;
  final bool isDateField;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Widget? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  const CustomTextField({
    super.key,
    required this.labelText,
    required this.controller,
    this.obscure = false,
    this.isDateField = false,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscure;
    _selectedDate = widget.initialDate;
  }

  Future<void> _selectDate(BuildContext context) async {
    final theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(1900),
      lastDate: widget.lastDate ?? DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        widget.controller.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters ?? [],
      obscureText: _obscureText,
      controller: widget.controller,
      readOnly: widget.isDateField,
      onTap: widget.isDateField ? () => _selectDate(context) : null,
      decoration: InputDecoration(
        labelText: widget.labelText,
        fillColor: theme.colorScheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: theme.colorScheme.outline.withAlpha(0x80)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: theme.colorScheme.outline.withAlpha(0x80)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: theme.colorScheme.outline.withAlpha(0x80)),
        ),
        suffixIcon: widget.suffixIcon != null
            ? GestureDetector(
                onTap: widget.onSuffixIconPressed,
                child: widget.suffixIcon,
              )
            : widget.obscure
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : widget.isDateField
                    ? Icon(
                        Icons.calendar_today,
                        color: theme.colorScheme.primary,
                        size: 20,
                      )
                    : null,
      ),
    );
  }
}
