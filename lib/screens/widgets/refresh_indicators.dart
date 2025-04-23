import 'package:flutter/cupertino.dart';
import 'package:easy_refresh/easy_refresh.dart';

/// A custom header indicator that follows Apple HIG guidelines
class AppleStyleHeader extends Header {
  /// Creates an Apple-style header indicator
  const AppleStyleHeader({
    super.triggerOffset = 100.0,
    super.clamping = false,
    super.position = IndicatorPosition.above,
    super.processedDuration = const Duration(milliseconds: 300),
    super.springRebound = false,
    super.hapticFeedback = true,
    super.safeArea = true,
    this.backgroundColor,
    this.foregroundColor,
    this.textStyle,
    this.messageText = 'Pull to refresh',
    this.readyText = 'Release to refresh',
    this.processingText = 'Refreshing...',
    this.processedText = 'Refreshed',
    this.failedText = 'Failed to refresh',
    this.noMoreText = 'No more data',
  });

  /// Background color of the indicator
  final Color? backgroundColor;

  /// Foreground color of the indicator (spinner and text)
  final Color? foregroundColor;

  /// Text style for the indicator messages
  final TextStyle? textStyle;

  /// Message when the indicator is in drag mode
  final String messageText;

  /// Message when the indicator is ready to trigger
  final String readyText;

  /// Message when the indicator is processing
  final String processingText;

  /// Message when the indicator has processed
  final String processedText;

  /// Message when the indicator has failed
  final String failedText;

  /// Message when there is no more data
  final String noMoreText;

  @override
  Widget build(BuildContext context, IndicatorState state) {
    final theme = CupertinoTheme.of(context);
    final bgColor = backgroundColor ?? theme.scaffoldBackgroundColor;
    final fgColor = foregroundColor ?? theme.primaryColor;
    final tStyle =
        textStyle ??
        TextStyle(color: theme.textTheme.textStyle.color, fontSize: 14);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: bgColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state.mode == IndicatorMode.processing ||
              state.mode == IndicatorMode.processed ||
              state.mode == IndicatorMode.ready &&
                  state.indicator.triggerOffset > 20)
            CupertinoActivityIndicator(color: fgColor, radius: 12),
          const SizedBox(width: 12),
          Text(_buildText(state), style: tStyle),
        ],
      ),
    );
  }

  String _buildText(IndicatorState state) {
    switch (state.mode) {
      case IndicatorMode.drag:
        return messageText;
      case IndicatorMode.armed:
      case IndicatorMode.ready:
        return readyText;
      case IndicatorMode.processing:
        return processingText;
      case IndicatorMode.processed:
        return processedText;
      case IndicatorMode.done:
        return '';
      case IndicatorMode.inactive:
        return '';
      default:
        return messageText;
    }
  }
}

/// A custom footer indicator that follows Apple HIG guidelines
class AppleStyleFooter extends Footer {
  /// Creates an Apple-style footer indicator
  const AppleStyleFooter({
    super.triggerOffset = 100.0,
    super.clamping = false,
    super.position = IndicatorPosition.above,
    super.processedDuration = const Duration(milliseconds: 300),
    super.springRebound = false,
    super.hapticFeedback = true,
    super.safeArea = true,
    this.backgroundColor,
    this.foregroundColor,
    this.textStyle,
    this.messageText = 'Pull to load more',
    this.readyText = 'Release to load more',
    this.processingText = 'Loading...',
    this.processedText = 'Loaded',
    this.failedText = 'Failed to load',
    this.noMoreText = 'No more data',
    this.showNoMoreText = true,
  });

  /// Background color of the indicator
  final Color? backgroundColor;

  /// Foreground color of the indicator (spinner and text)
  final Color? foregroundColor;

  /// Text style for the indicator messages
  final TextStyle? textStyle;

  /// Message when the indicator is in drag mode
  final String messageText;

  /// Message when the indicator is ready to trigger
  final String readyText;

  /// Message when the indicator is processing
  final String processingText;

  /// Message when the indicator has processed
  final String processedText;

  /// Message when the indicator has failed
  final String failedText;

  /// Message when there is no more data
  final String noMoreText;

  /// Whether to show the no more text
  final bool showNoMoreText;

  @override
  Widget build(BuildContext context, IndicatorState state) {
    final theme = CupertinoTheme.of(context);
    final bgColor = backgroundColor ?? theme.scaffoldBackgroundColor;
    final fgColor = foregroundColor ?? theme.primaryColor;
    final tStyle =
        textStyle ??
        TextStyle(color: theme.textTheme.textStyle.color, fontSize: 14);

    if (state.mode == IndicatorMode.inactive && !showNoMoreText) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: bgColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state.mode == IndicatorMode.processing ||
              state.mode == IndicatorMode.processed ||
              state.mode == IndicatorMode.ready &&
                  state.indicator.triggerOffset > 20)
            CupertinoActivityIndicator(color: fgColor, radius: 12),
          const SizedBox(width: 12),
          Text(_buildText(state), style: tStyle),
        ],
      ),
    );
  }

  String _buildText(IndicatorState state) {
    switch (state.mode) {
      case IndicatorMode.drag:
        return messageText;
      case IndicatorMode.armed:
      case IndicatorMode.ready:
        return readyText;
      case IndicatorMode.processing:
        return processingText;
      case IndicatorMode.processed:
        return processedText;
      case IndicatorMode.done:
        return '';
      case IndicatorMode.inactive:
        return noMoreText;
      default:
        return messageText;
    }
  }
}

/// A custom header indicator with a bouncing animation
class BouncingHeader extends Header {
  /// Creates a bouncing header indicator
  const BouncingHeader({
    super.triggerOffset = 100.0,
    super.clamping = false,
    super.position = IndicatorPosition.above,
    super.processedDuration = const Duration(milliseconds: 300),
    super.springRebound = true,
    super.hapticFeedback = true,
    super.safeArea = true,
    this.backgroundColor,
    this.foregroundColor,
    this.textStyle,
    this.messageText = 'Pull to refresh',
    this.readyText = 'Release to refresh',
    this.processingText = 'Refreshing...',
    this.processedText = 'Refreshed',
    this.failedText = 'Failed to refresh',
    this.noMoreText = 'No more data',
  });

  /// Background color of the indicator
  final Color? backgroundColor;

  /// Foreground color of the indicator (spinner and text)
  final Color? foregroundColor;

  /// Text style for the indicator messages
  final TextStyle? textStyle;

  /// Message when the indicator is in drag mode
  final String messageText;

  /// Message when the indicator is ready to trigger
  final String readyText;

  /// Message when the indicator is processing
  final String processingText;

  /// Message when the indicator has processed
  final String processedText;

  /// Message when the indicator has failed
  final String failedText;

  /// Message when there is no more data
  final String noMoreText;

  @override
  Widget build(BuildContext context, IndicatorState state) {
    final theme = CupertinoTheme.of(context);
    final bgColor = backgroundColor ?? theme.scaffoldBackgroundColor;
    final fgColor = foregroundColor ?? theme.primaryColor;
    final tStyle =
        textStyle ??
        TextStyle(color: theme.textTheme.textStyle.color, fontSize: 14);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: bgColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAnimatedIndicator(state, fgColor),
          const SizedBox(width: 12),
          Text(_buildText(state), style: tStyle),
        ],
      ),
    );
  }

  Widget _buildAnimatedIndicator(IndicatorState state, Color color) {
    if (state.mode == IndicatorMode.drag || state.mode == IndicatorMode.armed) {
      // Calculate rotation based on offset
      final progress = state.offset / state.indicator.triggerOffset;
      return Transform.rotate(
        angle: progress * 2 * 3.14159, // Full rotation
        child: Icon(
          CupertinoIcons.arrow_down_circle,
          color: color,
          size: 24 + (progress * 4), // Grow slightly with progress
        ),
      );
    } else if (state.mode == IndicatorMode.processing ||
        state.mode == IndicatorMode.ready) {
      return CupertinoActivityIndicator(color: color, radius: 12);
    } else if (state.mode == IndicatorMode.processed) {
      return Icon(CupertinoIcons.check_mark_circled, color: color, size: 24);
    } else {
      return const SizedBox(width: 24, height: 24);
    }
  }

  String _buildText(IndicatorState state) {
    switch (state.mode) {
      case IndicatorMode.drag:
        return messageText;
      case IndicatorMode.armed:
      case IndicatorMode.ready:
        return readyText;
      case IndicatorMode.processing:
        return processingText;
      case IndicatorMode.processed:
        return processedText;
      case IndicatorMode.done:
        return '';
      case IndicatorMode.inactive:
        return '';
      default:
        return messageText;
    }
  }
}

/// A custom footer indicator with a bouncing animation
class BouncingFooter extends Footer {
  /// Creates a bouncing footer indicator
  const BouncingFooter({
    super.triggerOffset = 100.0,
    super.clamping = false,
    super.position = IndicatorPosition.above,
    super.processedDuration = const Duration(milliseconds: 300),
    super.springRebound = true,
    super.hapticFeedback = true,
    super.safeArea = true,
    this.backgroundColor,
    this.foregroundColor,
    this.textStyle,
    this.messageText = 'Pull to load more',
    this.readyText = 'Release to load more',
    this.processingText = 'Loading...',
    this.processedText = 'Loaded',
    this.failedText = 'Failed to load',
    this.noMoreText = 'No more data',
    this.showNoMoreText = true,
  });

  /// Background color of the indicator
  final Color? backgroundColor;

  /// Foreground color of the indicator (spinner and text)
  final Color? foregroundColor;

  /// Text style for the indicator messages
  final TextStyle? textStyle;

  /// Message when the indicator is in drag mode
  final String messageText;

  /// Message when the indicator is ready to trigger
  final String readyText;

  /// Message when the indicator is processing
  final String processingText;

  /// Message when the indicator has processed
  final String processedText;

  /// Message when the indicator has failed
  final String failedText;

  /// Message when there is no more data
  final String noMoreText;

  /// Whether to show the no more text
  final bool showNoMoreText;

  @override
  Widget build(BuildContext context, IndicatorState state) {
    final theme = CupertinoTheme.of(context);
    final bgColor = backgroundColor ?? theme.scaffoldBackgroundColor;
    final fgColor = foregroundColor ?? theme.primaryColor;
    final tStyle =
        textStyle ??
        TextStyle(color: theme.textTheme.textStyle.color, fontSize: 14);

    if (state.mode == IndicatorMode.inactive && !showNoMoreText) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: bgColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAnimatedIndicator(state, fgColor),
          const SizedBox(width: 12),
          Text(_buildText(state), style: tStyle),
        ],
      ),
    );
  }

  Widget _buildAnimatedIndicator(IndicatorState state, Color color) {
    if (state.mode == IndicatorMode.drag || state.mode == IndicatorMode.armed) {
      // Calculate rotation based on offset
      final progress = state.offset / state.indicator.triggerOffset;
      return Transform.rotate(
        angle: progress * 2 * 3.14159, // Full rotation
        child: Icon(
          CupertinoIcons.arrow_up_circle,
          color: color,
          size: 24 + (progress * 4), // Grow slightly with progress
        ),
      );
    } else if (state.mode == IndicatorMode.processing ||
        state.mode == IndicatorMode.ready) {
      return CupertinoActivityIndicator(color: color, radius: 12);
    } else if (state.mode == IndicatorMode.processed) {
      return Icon(CupertinoIcons.check_mark_circled, color: color, size: 24);
    } else if (state.mode == IndicatorMode.inactive) {
      return Icon(CupertinoIcons.info_circle, color: color, size: 24);
    } else {
      return const SizedBox(width: 24, height: 24);
    }
  }

  String _buildText(IndicatorState state) {
    switch (state.mode) {
      case IndicatorMode.drag:
        return messageText;
      case IndicatorMode.armed:
      case IndicatorMode.ready:
        return readyText;
      case IndicatorMode.processing:
        return processingText;
      case IndicatorMode.processed:
        return processedText;
      case IndicatorMode.done:
        return '';
      case IndicatorMode.inactive:
        return noMoreText;
      default:
        return messageText;
    }
  }
}
