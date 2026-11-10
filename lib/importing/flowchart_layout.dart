import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import '../planner/course_template.dart';
import 'course_import.dart';

/// All geometry uses rendered page pixels with the origin at the top left.
class ChartText {
  const ChartText(this.text, this.bounds);
  final String text;
  final Rect bounds;
}

class FlowchartPage {
  const FlowchartPage(this.width, this.height, this.bgra, this.text);
  final int width, height;
  final Uint8List bgra;
  final List<ChartText> text;
}

class _Box {
  _Box(this.bounds, this.text);
  final Rect bounds;
  final List<ChartText> text;
  String? id;
}

/// Extract closed course boxes before interpreting their text. This avoids
/// borrowing a credit value or course reference from a neighbouring box/legend.
CourseImport parseFlowchartPages(
  List<FlowchartPage> pages, {
  int pageNumberOffset = 0,
}) {
  try {
    final recognized = parseCoursePdfText(
      pages.map((p) => _lines(p.text).join(' ')).join(' '),
    );
    if (recognized.supportedFlowchart) return recognized;
  } on FormatException {
    // Geometric extraction below may still identify elective-only boxes.
  }
  final courses = <ImportCourse>[];
  final links = <CourseLink>[];
  var ambiguous = 0;
  var slot = 0;
  for (var pageNumber = 0; pageNumber < pages.length; pageNumber++) {
    final page = pages[pageNumber];
    final w = page.width, h = page.height;
    if (page.bgra.length != w * h * 4) {
      throw const FormatException('Invalid flowchart page image.');
    }
    final ink = Uint8List(w * h);
    for (var i = 0; i < ink.length; i++) {
      final p = i * 4;
      ink[i] =
          page.bgra[p] < 200 &&
              page.bgra[p + 1] < 200 &&
              page.bgra[p + 2] < 200 &&
              page.bgra[p + 3] > 128
          ? 1
          : 0;
    }
    // Seal subpixel gaps in thin, anti-aliased box outlines.
    final barriers = Uint8List.fromList(ink);
    for (var y = 1; y < h - 1; y++) {
      for (var x = 1; x < w - 1; x++) {
        if (ink[y * w + x] == 0) continue;
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            barriers[(y + dy) * w + x + dx] = 1;
          }
        }
      }
    }
    // Bounded flood fills find interiors even with rounded corners and shading.
    final visited = Uint8List(w * h);
    final queue = Int32List(w * h);
    final boxes = <_Box>[];
    for (var seed = 0; seed < ink.length; seed++) {
      if (barriers[seed] != 0 || visited[seed] != 0) continue;
      var head = 0, tail = 1;
      queue[0] = seed;
      visited[seed] = 1;
      var left = w, right = 0, top = h, bottom = 0;
      while (head < tail) {
        final i = queue[head++], x = i % w, y = i ~/ w;
        left = math.min(left, x);
        right = math.max(right, x);
        top = math.min(top, y);
        bottom = math.max(bottom, y);
        for (final n in [
          if (x > 0) i - 1,
          if (x + 1 < w) i + 1,
          if (y > 0) i - w,
          if (y + 1 < h) i + w,
        ]) {
          if (barriers[n] == 0 && visited[n] == 0) {
            visited[n] = 1;
            queue[tail++] = n;
          }
        }
      }
      final bounds = Rect.fromLTRB(
        left.toDouble(),
        top.toDouble(),
        right + 1.0,
        bottom + 1.0,
      );
      if (left == 0 ||
          top == 0 ||
          right == w - 1 ||
          bottom == h - 1 ||
          bounds.width < w * .035 ||
          bounds.width > w * .3 ||
          bounds.height < h * .025 ||
          bounds.height > h * .18 ||
          tail < bounds.width * bounds.height * .45) {
        continue;
      }
      final text = page.text
          .where((t) => bounds.contains(t.bounds.center))
          .toList();
      final content = _lines(text).join(' ');
      if (!RegExp(r'\(\s*\d{1,2}\s*\)').hasMatch(content)) continue;
      boxes.add(_Box(bounds, text));
    }
    if (boxes.isEmpty) continue;
    // Column centres come from the detected boxes, not fixed LSU coordinates.
    boxes.sort((a, b) => a.bounds.center.dx.compareTo(b.bounds.center.dx));
    final typicalWidth = (boxes.map((b) => b.bounds.width).toList()
      ..sort())[boxes.length ~/ 2];
    final columns = <double>[];
    for (final box in boxes) {
      if (columns.isEmpty ||
          box.bounds.center.dx - columns.last > typicalWidth * .6) {
        columns.add(box.bounds.center.dx);
      }
    }
    if (columns.length > 10) continue;
    boxes.sort((a, b) {
      final x = a.bounds.center.dx.compareTo(b.bounds.center.dx);
      return x == 0 ? a.bounds.top.compareTo(b.bounds.top) : x;
    });
    for (final box in boxes) {
      final lines = _lines(box.text);
      final content = lines.join(' ');
      final code = courseCodePattern.firstMatch(content.toUpperCase());
      final credits = RegExp(r'\(\s*(\d{1,2})\s*\)').firstMatch(content);
      final credit = int.tryParse(credits?[1] ?? '');
      final id = code == null
          ? 'PDF${pageNumber + 1 + pageNumberOffset}-SLOT${++slot}'
          : '${code[1]} ${code[2]}';
      // More than one code in a box is an alternative requirement, not two courses.
      final alternatives =
          RegExp(
            r'\b(?:or|Gen Ed)\b',
            caseSensitive: false,
          ).hasMatch(content) ||
          courseCodePattern.allMatches(content.toUpperCase()).length > 1;
      box.id = alternatives
          ? 'PDF${pageNumber + 1 + pageNumberOffset}-SLOT${++slot}'
          : id;
      var title = content
          .replaceAll(RegExp(r'\(\s*\d{1,2}\s*\)'), '')
          .replaceAll(RegExp(r'[_*]+'), '')
          .trim();
      if (code != null && !alternatives) {
        title = title.replaceFirst(code.group(0)!, '');
      }
      title = title
          .replaceAll(RegExp(r'\b[CFSP]\b'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      var column = 0;
      for (var i = 1; i < columns.length; i++) {
        if ((columns[i] - box.bounds.center.dx).abs() <
            (columns[column] - box.bounds.center.dx).abs()) {
          column = i;
        }
      }
      if (courses.any((c) => c.id == box.id)) {
        ambiguous++;
        box.id = null;
        continue;
      }
      courses.add(
        ImportCourse(
          box.id!,
          title.isEmpty ? box.id! : title,
          credit != null && credit >= 1 && credit <= 12 ? credit : null,
          column + 1,
          minimumC: RegExp(r'\bC\b').hasMatch(content),
          offered: RegExp(r'\bF\b').hasMatch(content)
              ? 'Fall'
              : RegExp(r'\bS\b').hasMatch(content)
              ? 'Spring'
              : null,
        ),
      );
    }
    // Erase box outlines/interiors and page text. Only connectors remain.
    final connectors = Uint8List.fromList(ink);
    void erase(Rect r) {
      for (
        var y = math.max(0, r.top.floor());
        y < math.min(h, r.bottom.ceil());
        y++
      ) {
        for (
          var x = math.max(0, r.left.floor());
          x < math.min(w, r.right.ceil());
          x++
        ) {
          connectors[y * w + x] = 0;
        }
      }
    }

    for (final box in boxes) {
      erase(box.bounds.inflate(3));
    }
    for (final text in page.text.where((t) => t.text.trim().isNotEmpty)) {
      erase(text.bounds.inflate(1));
    }
    // Components are deliberately conservative: touching/crossing branches
    // are reported for review instead of producing an all-to-all dependency.
    visited.fillRange(0, visited.length, 0);
    for (var seed = 0; seed < connectors.length; seed++) {
      if (connectors[seed] == 0 || visited[seed] != 0) continue;
      var head = 0, tail = 1;
      queue[0] = seed;
      visited[seed] = 1;
      final contacts = <_Box, List<Offset>>{};
      while (head < tail) {
        final i = queue[head++], x = i % w, y = i ~/ w;
        final point = Offset(x.toDouble(), y.toDouble());
        for (final box in boxes) {
          if (box.id != null && box.bounds.inflate(12).contains(point)) {
            contacts.putIfAbsent(box, () => []).add(point);
          }
        }
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            final nx = x + dx, ny = y + dy;
            if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
            final n = ny * w + nx;
            if (connectors[n] != 0 && visited[n] == 0) {
              visited[n] = 1;
              queue[tail++] = n;
            }
          }
        }
      }
      if (tail < 12 || contacts.length < 2) continue;
      if (contacts.length != 2) {
        ambiguous++;
        continue;
      }
      // A filled arrowhead has a broad footprint beside its target box.
      // Equal footprints (including open/dashed heads) need manual direction.
      final ends = contacts.entries.toList();
      double spread(List<Offset> points) {
        var l = double.infinity, r = -double.infinity;
        var t = double.infinity, b = -double.infinity;
        for (final p in points) {
          l = math.min(l, p.dx);
          r = math.max(r, p.dx);
          t = math.min(t, p.dy);
          b = math.max(b, p.dy);
        }
        return math.min(r - l, b - t);
      }

      final a = spread(ends[0].value), b = spread(ends[1].value);
      if ((a - b).abs() < 1.5 || math.max(a, b) < 2.5) {
        ambiguous++;
        continue;
      }
      final source = ends[a < b ? 0 : 1].key.id!;
      final target = ends[a < b ? 1 : 0].key.id!;
      if (!links.any((l) => l.from == source && l.to == target)) {
        links.add(CourseLink(source, target));
      }
    }
  }
  if (courses.isEmpty) {
    return parseCoursePdfText(
      pages.map((p) => _lines(p.text).join(' ')).join(' '),
    );
  }
  return CourseImport(
    courses,
    'Read ${courses.length} course and elective boxes using their page positions. '
    'Review credits, semester columns, and all connections against the preview. '
    '${links.length} solid-arrow candidates detected; $ambiguous ambiguous connector groups were left unconnected. '
    'Dashed, branching, crossing, and alternative arrows may need manual connections. '
    'No grades or personal progress were imported.',
    links: links,
  );
}

List<String> _lines(List<ChartText> text) {
  final indices = {for (var i = 0; i < text.length; i++) text[i]: i};
  final sorted = text.where((t) => t.text.trim().isNotEmpty).toList()
    ..sort((a, b) => a.bounds.center.dy.compareTo(b.bounds.center.dy));
  final rows = <List<ChartText>>[];
  for (final t in sorted) {
    if (rows.isEmpty ||
        (rows.last.first.bounds.center.dy - t.bounds.center.dy).abs() >
            math.max(t.bounds.height * .55, 2)) {
      rows.add([]);
    }
    rows.last.add(t);
  }
  return rows.map((row) {
    row.sort((a, b) => a.bounds.left.compareTo(b.bounds.left));
    final buffer = StringBuffer();
    ChartText? previous;
    for (final t in row) {
      final before = previous == null ? -1 : indices[previous]!;
      final after = indices[t]!;
      final explicitSpace =
          before >= 0 &&
          after > before &&
          after - before <= 4 &&
          text.sublist(before + 1, after).any((c) => c.text.trim().isEmpty);
      if (previous != null &&
          (explicitSpace ||
              t.bounds.left - previous.bounds.right >
                  math.max(t.bounds.height, previous.bounds.height) * .45)) {
        buffer.write(' ');
      }
      buffer.write(t.text);
      previous = t;
    }
    return buffer.toString();
  }).toList();
}
