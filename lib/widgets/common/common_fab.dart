import 'package:flutter/material.dart';

class CommonFab extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;

  const CommonFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      elevation: 4,
      child: Icon(icon),
    );
  }
}
