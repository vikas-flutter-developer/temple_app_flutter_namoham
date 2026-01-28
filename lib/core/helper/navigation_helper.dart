import 'package:flutter/material.dart';

void navigateToPage(BuildContext context, Widget page) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => page),
  );
}

void navigateToPageReplacement(BuildContext context, Widget page) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => page),
  );
}

/// Navigates to a new page and removes all previous pages from the stack.
/// Use this for Login -> Home or Logout -> Login transitions.
void navigateToPageAndRemoveUntil(BuildContext context, Widget page) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => page),
        (Route<dynamic> route) => false, // This condition removes all previous routes
  );
}

void navigateBack(BuildContext context) {
  Navigator.pop(context);
}