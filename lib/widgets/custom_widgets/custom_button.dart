import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  final String labelText;
  final VoidCallback? onPressed; 
  final Color? backgroundColor;

  const CustomButton({
    super.key,
    required this.labelText,
    required this.onPressed,
    this.backgroundColor,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: widget.onPressed, 
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.backgroundColor ?? theme.colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text(
            widget.labelText,
            style: TextStyle(
              fontSize: 18,
              color: theme.colorScheme.surface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
