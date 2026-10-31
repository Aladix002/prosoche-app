import 'package:flutter/material.dart';

/// Docasna obrazovka s nazvom, kym feature uloha nedoda skutocne UI.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.title,
    this.body,
    this.automaticallyImplyLeading = true,
    super.key,
  });

  final String title;
  final Widget? body;
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      automaticallyImplyLeading: automaticallyImplyLeading,
    ),
    body: SafeArea(child: Center(child: body ?? Text(title))),
  );
}
