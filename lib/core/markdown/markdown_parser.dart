import 'dart:convert';

import 'package:flutter/foundation.dart';

/// A parsed Markdown block.
@immutable
sealed class MarkdownBlock {
  const MarkdownBlock();
}

class MarkdownHeading extends MarkdownBlock {
  const MarkdownHeading({required this.level, required this.spans});

  /// 1, 2 or 3. Deeper levels are parsed as level 3.
  final int level;
  final List<MarkdownSpan> spans;
}

class MarkdownParagraph extends MarkdownBlock {
  const MarkdownParagraph(this.spans);

  final List<MarkdownSpan> spans;
}

class MarkdownList extends MarkdownBlock {
  const MarkdownList({required this.ordered, required this.items});

  final bool ordered;
  final List<List<MarkdownSpan>> items;
}

/// A run of inline text with its formatting resolved.
@immutable
class MarkdownSpan {
  const MarkdownSpan(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.link,
  });

  final String text;
  final bool bold;
  final bool italic;

  /// Destination when this span is a link, else `null`.
  final String? link;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarkdownSpan &&
          other.text == text &&
          other.bold == bold &&
          other.italic == italic &&
          other.link == link;

  @override
  int get hashCode => Object.hash(text, bold, italic, link);

  @override
  String toString() =>
      'MarkdownSpan($text, bold: $bold, italic: $italic, link: $link)';
}

/// Parser for the Markdown subset our legal documents use.
///
/// Supported: ATX headings (`#`..`###`), paragraphs, unordered lists (`-`,
/// `*`, `+`), ordered lists (`1.`), `**bold**`, `*italic*`/`_italic_`, and
/// `[label](https://…)` links.
///
/// Anything else is emitted as literal text rather than dropped. That is the
/// deliberate choice for legal copy: rendering an unsupported construct
/// verbatim is visible and correctable, while silently swallowing it could
/// remove a legally required sentence without anyone noticing.
abstract final class MarkdownParser {
  static final _headingPattern = RegExp(r'^(#{1,6})\s+(.*)$');
  static final _bulletPattern = RegExp(r'^\s*[-*+]\s+(.*)$');
  static final _orderedPattern = RegExp(r'^\s*\d+[.)]\s+(.*)$');
  static final _inlinePattern = RegExp(
    r'\[([^\]]+)\]\(([^)\s]+)\)' // [label](url)
    r'|\*\*([^*]+)\*\*' // **bold**
    r'|__([^_]+)__' // __bold__
    r'|\*([^*]+)\*' // *italic*
    r'|_([^_]+)_', // _italic_
  );

  static List<MarkdownBlock> parse(String source) {
    final blocks = <MarkdownBlock>[];
    final paragraph = <String>[];
    final listItems = <List<MarkdownSpan>>[];
    var listOrdered = false;

    void flushParagraph() {
      if (paragraph.isEmpty) return;
      blocks.add(MarkdownParagraph(parseInline(paragraph.join(' '))));
      paragraph.clear();
    }

    void flushList() {
      if (listItems.isEmpty) return;
      blocks.add(
        MarkdownList(
          ordered: listOrdered,
          items: List<List<MarkdownSpan>>.of(listItems),
        ),
      );
      listItems.clear();
    }

    for (final rawLine in const LineSplitter().convert(source)) {
      final line = rawLine.trimRight();

      if (line.trim().isEmpty) {
        flushParagraph();
        flushList();
        continue;
      }

      final heading = _headingPattern.firstMatch(line);
      if (heading != null) {
        flushParagraph();
        flushList();
        blocks.add(
          MarkdownHeading(
            level: heading.group(1)!.length.clamp(1, 3),
            spans: parseInline(heading.group(2)!.trim()),
          ),
        );
        continue;
      }

      final ordered = _orderedPattern.firstMatch(line);
      final bullet = ordered == null ? _bulletPattern.firstMatch(line) : null;
      if (ordered != null || bullet != null) {
        flushParagraph();
        final isOrdered = ordered != null;
        // A change of list type starts a new list rather than mixing markers.
        if (listItems.isNotEmpty && isOrdered != listOrdered) flushList();
        listOrdered = isOrdered;
        listItems.add(parseInline((ordered ?? bullet)!.group(1)!.trim()));
        continue;
      }

      flushList();
      paragraph.add(line.trim());
    }

    flushParagraph();
    flushList();
    return blocks;
  }

  /// Splits one line into formatted spans.
  static List<MarkdownSpan> parseInline(String source) {
    if (source.isEmpty) return const <MarkdownSpan>[];

    final spans = <MarkdownSpan>[];
    var cursor = 0;

    for (final match in _inlinePattern.allMatches(source)) {
      if (match.start > cursor) {
        spans.add(MarkdownSpan(source.substring(cursor, match.start)));
      }
      final link = match.group(1);
      if (link != null) {
        spans.add(MarkdownSpan(link, link: match.group(2)));
      } else if (match.group(3) != null || match.group(4) != null) {
        spans.add(
          MarkdownSpan(match.group(3) ?? match.group(4)!, bold: true),
        );
      } else {
        spans.add(
          MarkdownSpan(match.group(5) ?? match.group(6)!, italic: true),
        );
      }
      cursor = match.end;
    }

    if (cursor < source.length) {
      spans.add(MarkdownSpan(source.substring(cursor)));
    }
    return spans;
  }
}
