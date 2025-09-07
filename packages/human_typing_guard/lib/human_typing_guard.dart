/// Flutter Human Typing Guard
/// 
/// A package that detects human typing patterns to prevent bots using
/// speed, variability, cadence, and entropy analysis without storing
/// personal data.
library human_typing_guard;

// Core classes
export 'src/core/typing_guard.dart';
export 'src/core/typing_analyzer.dart';

// Models
export 'src/models/typing_event.dart';
export 'src/models/guard_result.dart';
export 'src/models/typing_features.dart';
export 'src/models/typing_guard_config.dart';

// Widgets
export 'src/widgets/typing_guard_widget.dart';

// Client (optional)
export 'src/client/typing_guard_client.dart';
