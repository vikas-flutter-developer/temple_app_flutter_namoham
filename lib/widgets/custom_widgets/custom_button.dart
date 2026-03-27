import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  final String labelText;
  final VoidCallback? onPressed; 
  final Color? backgroundColor;
  final bool useGradient;
  final Gradient? gradient;

  const CustomButton({
    super.key,
    required this.labelText,
    required this.onPressed,
    this.backgroundColor,
    this.useGradient = true,
    this.gradient,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultGradient = LinearGradient(
      colors: [
        const Color(0xFF1565C0), // Deep Blue
        const Color(0xFF42A5F5), // Light Blue
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Center(
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: widget.useGradient ? (widget.gradient ?? defaultGradient) : null,
          color: !widget.useGradient ? (widget.backgroundColor ?? theme.colorScheme.primary) : null,
          boxShadow: [
            BoxShadow(
              color: (widget.useGradient 
                  ? const Color(0xFF1565C0) 
                  : (widget.backgroundColor ?? theme.colorScheme.primary)).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: widget.onPressed, 
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            widget.labelText,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
