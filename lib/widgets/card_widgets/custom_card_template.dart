import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CustomCardTemplate extends StatefulWidget {
  final String title;
  final String subtitle;
  final String image;
  final Function()? onTap;
  const CustomCardTemplate(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.onTap,
      required this.image});

  @override
  State<CustomCardTemplate> createState() => _CustomCardTemplateState();
}

class _CustomCardTemplateState extends State<CustomCardTemplate> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        height: 220,
        decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.colorScheme.outline)),
        child: Column(
          children: [
            const SizedBox(height: 15),
            SvgPicture.asset(widget.image),
            const SizedBox(height: 15),
            Text(widget.title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.subtitle,
                style:
                    TextStyle(fontSize: 14, color: theme.colorScheme.outline)),
          ],
        ),
      ),
    );
  }
}
