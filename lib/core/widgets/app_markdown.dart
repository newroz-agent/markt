import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:zerin_marketplace/core/markdown/markdown_parser.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';

/// Renders the Markdown subset described by [MarkdownParser].
///
/// Built for legal copy: selectable so users can quote it, and links are
/// handed back through [onLinkTap] rather than opened here, so the caller
/// decides what leaving the app means.
class AppMarkdown extends StatefulWidget {
  const AppMarkdown({
    required this.source,
    this.onLinkTap,
    super.key,
  });

  final String source;
  final void Function(String url)? onLinkTap;

  @override
  State<AppMarkdown> createState() => _AppMarkdownState();
}

class _AppMarkdownState extends State<AppMarkdown> {
  /// Recognizers are long-lived objects that must be disposed; building them
  /// inline in [build] would leak one per link per frame.
  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];

  late List<MarkdownBlock> _blocks;

  @override
  void initState() {
    super.initState();
    _blocks = MarkdownParser.parse(widget.source);
  }

  @override
  void didUpdateWidget(AppMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _blocks = MarkdownParser.parse(widget.source);
    }
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _disposeRecognizers();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final (index, block) in _blocks.indexed) ...<Widget>[
          if (index > 0) SizedBox(height: _spacingBefore(block)),
          _buildBlock(context, theme, block),
        ],
      ],
    );
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  double _spacingBefore(MarkdownBlock block) =>
      block is MarkdownHeading ? AppSpacing.lg : AppSpacing.md;

  Widget _buildBlock(
    BuildContext context,
    ThemeData theme,
    MarkdownBlock block,
  ) {
    return switch (block) {
      MarkdownHeading(:final level, :final spans) => Semantics(
        header: true,
        child: SelectableText.rich(
          _toTextSpan(context, spans, _headingStyle(theme, level)),
        ),
      ),
      MarkdownParagraph(:final spans) => SelectableText.rich(
        _toTextSpan(context, spans, theme.textTheme.bodyMedium),
      ),
      MarkdownList(:final ordered, :final items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final (index, item) in items.indexed) ...<Widget>[
            if (index > 0) const SizedBox(height: AppSpacing.xs),
            _buildListItem(context, theme, item, ordered ? index + 1 : null),
          ],
        ],
      ),
    };
  }

  Widget _buildListItem(
    BuildContext context,
    ThemeData theme,
    List<MarkdownSpan> spans,
    int? number,
  ) {
    final marker = number == null ? '•' : '$number.';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Excluded from semantics: a screen reader announces list position
        // from the structure, and reading "bullet" before every item is noise.
        ExcludeSemantics(
          child: SizedBox(
            width: AppSpacing.lg,
            child: Text(marker, style: theme.textTheme.bodyMedium),
          ),
        ),
        Expanded(
          child: SelectableText.rich(
            _toTextSpan(context, spans, theme.textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }

  TextStyle? _headingStyle(ThemeData theme, int level) => switch (level) {
    1 => theme.textTheme.headlineSmall,
    2 => theme.textTheme.titleLarge,
    _ => theme.textTheme.titleMedium,
  };

  TapGestureRecognizer _recognizerFor(String url) {
    final recognizer = TapGestureRecognizer()
      ..onTap = () => widget.onLinkTap!(url);
    _recognizers.add(recognizer);
    return recognizer;
  }

  TextSpan _toTextSpan(
    BuildContext context,
    List<MarkdownSpan> spans,
    TextStyle? base,
  ) {
    final linkColor = Theme.of(context).colorScheme.primary;
    return TextSpan(
      children: <InlineSpan>[
        for (final span in spans)
          TextSpan(
            text: span.text,
            style: base?.copyWith(
              fontWeight: span.bold ? FontWeight.w600 : null,
              fontStyle: span.italic ? FontStyle.italic : null,
              color: span.link == null ? null : linkColor,
              decoration: span.link == null ? null : TextDecoration.underline,
              decorationColor: span.link == null ? null : linkColor,
            ),
            recognizer: span.link == null || widget.onLinkTap == null
                ? null
                : _recognizerFor(span.link!),
          ),
      ],
    );
  }
}
