import 'package:flutter/material.dart';

/// Renders long-form legal / informational content (About, Privacy, Terms)
/// as a set of formal, attractive document cards.
///
/// The raw content uses a light convention:
///   • UPPERCASE lines            -> a document title band
///   • "1." top-level numbered    -> its own card, headed by a number badge
///   • "5.1" sub numbered         -> a sub-heading inside the current card
///   • lines starting with "•"    -> bullet points
///   • everything else            -> body paragraphs
class StaticContentPage extends StatelessWidget {
  const StaticContentPage({
    super.key,
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  static const _ink = Color(0xFF243041);
  static const _body = Color(0xFF44515F);
  static const _muted = Color(0xFF8E98A5);
  static const _accent = Color(0xFF5A91C4);
  static const _border = Color(0xFFE7ECF3);
  static const _bg = Color(0xFFF5F8FC);

  static const _badgeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5A91C4), Color(0xFF3F6E9E)],
  );

  static final _numbered = RegExp(r'^(\d+(?:\.\d+)*)\.?\s+(.*)$');
  // "Label: value" field lines (short label only, so prose colons are ignored).
  static final _field = RegExp(r'^([^:]{1,22}):\s+(.+)$');

  @override
  Widget build(BuildContext context) {
    final docs = _parse(content);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _bg,
        surfaceTintColor: _bg,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.chevron_left, color: _ink, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _hero(),
          const SizedBox(height: 18),
          for (final doc in docs)
            if (doc.isTitle)
              _titleBand(doc.title!)
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _card(doc),
              ),
          const SizedBox(height: 6),
          _footer(),
        ],
      ),
    );
  }

  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: _badgeGradient,
        boxShadow: const [
          BoxShadow(
            color: Color(0x335A91C4),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Books on Wheels',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _titleBand(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: 0.6,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Center(
      child: Text(
        '© Books on Wheels',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: _muted.withValues(alpha: 0.9),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _card(_Doc doc) {
    final hasHeader = doc.number != null || doc.heading != null;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1F3B5C),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasHeader) _cardHeader(doc.number, doc.heading),
          for (final block in doc.blocks) _block(block),
        ],
      ),
    );
  }

  Widget _cardHeader(String? number, String? heading) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (number != null) ...[
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: _badgeGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x335A91C4),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              heading ?? '',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _ink,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _block(_Block block) {
    switch (block.type) {
      case _BlockType.subheading:
        return _subheading(block.number!, block.text);
      case _BlockType.bullet:
        return _bullet(block.text);
      case _BlockType.paragraph:
        return _paragraph(block.text);
    }
  }

  Widget _subheading(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _accent,
              height: 1.35,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: _ink,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, top: 6, bottom: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7, right: 10),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: _accent,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                color: _body,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paragraph(String text) {
    final field = _field.firstMatch(text);
    if (field != null) {
      final label = field.group(1)!.trim();
      final value = field.group(2)!.trim();
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 2),
        child: Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 13.5, height: 1.65),
            children: [
              TextSpan(
                text: '$label: ',
                style: const TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: value,
                style: const TextStyle(color: _body),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13.5, color: _body, height: 1.65),
      ),
    );
  }

  List<_Doc> _parse(String raw) {
    final docs = <_Doc>[];
    List<_Block>? blocks;

    void newCard({String? number, String? heading}) {
      blocks = <_Block>[];
      docs.add(_Doc.card(number: number, heading: heading, blocks: blocks!));
    }

    void ensureCard() {
      if (blocks == null) newCard();
    }

    for (final rawLine in raw.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (_isTitle(line)) {
        docs.add(_Doc.title(line));
        blocks = null;
        continue;
      }

      if (line.startsWith('•')) {
        ensureCard();
        blocks!.add(_Block(_BlockType.bullet, line.substring(1).trim()));
        continue;
      }

      final match = _numbered.firstMatch(line);
      if (match != null) {
        final number = match.group(1)!;
        final rest = match.group(2)!.trim();
        if (number.contains('.')) {
          ensureCard();
          blocks!.add(
            _Block(_BlockType.subheading, rest, number: number),
          );
        } else {
          newCard(number: number, heading: rest);
        }
        continue;
      }

      ensureCard();
      blocks!.add(_Block(_BlockType.paragraph, line));
    }

    return docs;
  }

  bool _isTitle(String line) {
    if (line.length > 60) return false;
    if (line.contains(RegExp(r'\d'))) return false;
    if (!line.contains(RegExp(r'[A-Za-zÀ-ÿ]'))) return false;
    return line == line.toUpperCase();
  }
}

enum _BlockType { subheading, bullet, paragraph }

class _Block {
  _Block(this.type, this.text, {this.number});

  final _BlockType type;
  final String text;
  final String? number;
}

class _Doc {
  _Doc.title(this.title)
    : isTitle = true,
      number = null,
      heading = null,
      blocks = const [];

  _Doc.card({this.number, this.heading, required this.blocks})
    : isTitle = false,
      title = null;

  final bool isTitle;
  final String? title;
  final String? number;
  final String? heading;
  final List<_Block> blocks;
}
