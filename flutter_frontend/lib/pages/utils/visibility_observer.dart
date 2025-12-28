import 'package:flutter/material.dart';

class VisibilityObserver extends StatefulWidget {
  final Widget child;
  const VisibilityObserver({super.key, required this.child});

  @override
  State<VisibilityObserver> createState() =>
      _VisibilityObserverState();
}

class _VisibilityObserverState extends State<VisibilityObserver>
    with WidgetsBindingObserver {

  bool _active = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _active = state == AppLifecycleState.resumed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = ModalRoute.of(context)?.isCurrent ?? true;
    return TickerMode(
      enabled: _active && visible,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
