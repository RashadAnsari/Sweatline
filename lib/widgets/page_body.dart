import 'package:flutter/material.dart';

/// Responsive content container: full width on phones, centered with a
/// comfortable reading width on tablets and large screens.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child});

  static const maxWidth = 640.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // heightFactor 1 keeps the wrapper as tall as its child, so PageBody is
    // safe inside bottom bars and other intrinsically sized slots too.
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
