import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/typing_event.dart';
import '../models/guard_result.dart';
import '../models/typing_guard_config.dart';
import '../core/typing_guard.dart';

/// Widget that wraps input fields and automatically analyzes typing patterns
class TypingGuardWidget extends StatefulWidget {
  /// The typing guard instance to use
  final TypingGuard guard;
  
  /// Child widget (typically a TextField or TextFormField)
  final Widget child;
  
  /// Callback for analysis results
  final void Function(GuardResult result)? onResult;
  
  /// Whether to show visual feedback (score indicator)
  final bool showFeedback;
  
  /// Custom feedback widget builder
  final Widget Function(GuardResult result)? feedbackBuilder;

  const TypingGuardWidget({
    super.key,
    required this.guard,
    required this.child,
    this.onResult,
    this.showFeedback = false,
    this.feedbackBuilder,
  });

  @override
  State<TypingGuardWidget> createState() => _TypingGuardWidgetState();
}

class _TypingGuardWidgetState extends State<TypingGuardWidget> {
  late StreamSubscription<GuardResult> _resultSubscription;
  GuardResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _resultSubscription = widget.guard.results.listen((result) {
      setState(() {
        _lastResult = result;
      });
      widget.onResult?.call(result);
    });
  }

  @override
  void dispose() {
    _resultSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main input widget
        _buildInputWidget(),
        
        // Optional feedback
        if (widget.showFeedback && _lastResult != null)
          _buildFeedback(),
      ],
    );
  }

  Widget _buildInputWidget() {
    return _TypingGuardInheritedWidget(
      guard: widget.guard,
      child: widget.child,
    );
  }

  Widget _buildFeedback() {
    if (widget.feedbackBuilder != null) {
      return widget.feedbackBuilder!(_lastResult!);
    }
    
    return _DefaultFeedbackWidget(result: _lastResult!);
  }
}

/// Inherited widget to provide typing guard to child widgets
class _TypingGuardInheritedWidget extends InheritedWidget {
  final TypingGuard guard;

  const _TypingGuardInheritedWidget({
    required this.guard,
    required super.child,
  });

  @override
  bool updateShouldNotify(_TypingGuardInheritedWidget oldWidget) {
    return guard != oldWidget.guard;
  }

  static TypingGuard? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_TypingGuardInheritedWidget>()?.guard;
  }
}

/// Default feedback widget showing score and status
class _DefaultFeedbackWidget extends StatelessWidget {
  final GuardResult result;

  const _DefaultFeedbackWidget({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.only(top: 4.0),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: _getStatusColor().withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 16,
            color: _getStatusColor(),
          ),
          const SizedBox(width: 8),
          Text(
            'Score: ${(result.score * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12,
              color: _getStatusColor(),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (result.score >= 0.7) return Colors.green;
    if (result.score >= 0.4) return Colors.orange;
    return Colors.red;
  }

  IconData _getStatusIcon() {
    if (result.score >= 0.7) return Icons.check_circle;
    if (result.score >= 0.4) return Icons.warning;
    return Icons.error;
  }
}

/// Mixin for TextEditingController to automatically capture typing events
mixin TypingGuardMixin on TextEditingController {
  TypingGuard? _guard;
  String _previousText = '';

  /// Initialize the typing guard
  void initTypingGuard(TypingGuard guard) {
    _guard = guard;
    addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_guard == null) return;

    final currentText = text;
    final currentLength = currentText.length;
    final previousLength = _previousText.length;

    // Detect typing events
    if (currentLength > previousLength) {
      // Text was added
      final addedText = currentText.substring(previousLength);
      if (addedText.length == 1) {
        // Single character typed
        _guard!.addEvent(TypingEvent.character(
          timestamp: DateTime.now().millisecondsSinceEpoch,
          character: addedText,
        ));
      } else {
        // Multiple characters (likely paste)
        _guard!.addEvent(TypingEvent.paste(
          timestamp: DateTime.now().millisecondsSinceEpoch,
          pastedText: addedText,
        ));
      }
    } else if (currentLength < previousLength) {
      // Text was removed (backspace)
      _guard!.addEvent(TypingEvent.backspace(
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }

    _previousText = currentText;
  }

  @override
  void dispose() {
    removeListener(_onTextChanged);
    super.dispose();
  }
}

/// Extension to easily add typing guard to TextEditingController
extension TypingGuardController on TextEditingController {
  /// Add typing guard to this controller
  void withTypingGuard(TypingGuard guard) {
    if (this is TypingGuardMixin) {
      (this as TypingGuardMixin).initTypingGuard(guard);
    }
  }
}
