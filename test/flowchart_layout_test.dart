import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:project6graduate/importing/flowchart_layout.dart';

FlowchartPage fixture() {
  final data = jsonDecode(
    File('test/fixtures/csc_dsa_layout.json').readAsStringSync(),
  );
  final pixels = Uint8List.fromList(
    gzip.decode(File('test/fixtures/csc_dsa_pixels.bgra.gz').readAsBytesSync()),
  );
  final text = (data['text'] as List).map((t) {
    final r = t['rect'] as List;
    return ChartText(
      t['text'],
      Rect.fromLTRB(
        (r[0] as num).toDouble(),
        (r[1] as num).toDouble(),
        (r[2] as num).toDouble(),
        (r[3] as num).toDouble(),
      ),
    );
  }).toList();
  return FlowchartPage(data['width'], data['height'], pixels, text);
}

void main() {
  test(
    'provided CSC DSA chart reads boxes, electives and column placements',
    () {
      final result = parseFlowchartPages([fixture()]);
      expect(result.courses.length, 40);
      expect(result.courses.fold<int>(0, (s, c) => s + (c.credits ?? 0)), 120);
      final first = result.courses.singleWhere((c) => c.id == 'CSC 1350');
      expect(first.credits, 4);
      expect(first.semester, 1);
      expect(first.minimumC, isTrue);
      expect(
        result.courses.singleWhere((c) => c.id == 'CSC 4402').minimumC,
        isFalse,
      );
      expect(
        result.links.any((l) => l.from == 'CSC 1350' && l.to == 'CSC 1351'),
        isTrue,
      );
      expect(
        result.courses.singleWhere((c) => c.id == 'CSC 2730').offered,
        'Fall',
      );
      expect(result.courses.singleWhere((c) => c.id == 'CSC 4343').semester, 8);
      expect(result.courses.any((c) => c.id == 'CSC 4444'), isFalse);
      expect(result.courses.where((c) => c.id.contains('SLOT')), isNotEmpty);
    },
  );
  test('moving the chart and changing a credit value does not use fixed coordinates', () {
    final page = fixture();
    const dx = 40, dy = 25;
    final w = page.width + dx * 2, h = page.height + dy * 2;
    final pixels = Uint8List(w * h * 4)..fillRange(0, w * h * 4, 255);
    for (var y = 0; y < page.height; y++) {
      pixels.setRange(
        ((y + dy) * w + dx) * 4,
        ((y + dy) * w + dx + page.width) * 4,
        page.bgra,
        y * page.width * 4,
      );
    }
    var changed = false;
    final text = page.text.map((t) {
      final change =
          !changed &&
          t.text == '4' &&
          t.bounds.center.dx < page.width * .15 &&
          t.bounds.center.dy < page.height * .25;
      if (change) changed = true;
      return ChartText(
        change ? '2' : t.text,
        t.bounds.shift(const Offset(dx * 1.0, dy * 1.0)),
      );
    }).toList();
    expect(changed, true);
    final result = parseFlowchartPages([FlowchartPage(w, h, pixels, text)]);
    expect(result.courses.length, 40);
    expect(result.courses.singleWhere((c) => c.id == 'CSC 1350').credits, 2);
    expect(
      result.courses.fold<int>(0, (sum, c) => sum + (c.credits ?? 0)),
      118,
    );
    expect(result.courses.singleWhere((c) => c.id == 'CSC 4343').semester, 8);
    expect(
      result.links.any((l) => l.from == 'CSC 1350' && l.to == 'CSC 1351'),
      true,
    );
  });
}
