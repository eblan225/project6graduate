import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:project6graduate/importing/flowchart_layout.dart';

void main() {
  test(
    'native reader extracts supplied PDF',
    () async {
      await pdfrxInitialize(tmpPath: '/tmp/pdfrx-flowchart-check');
      final doc = await PdfDocument.openData(
        await File('test/fixtures/csc_dsa_2026_2027.pdf').readAsBytes(),
      );
      try {
        final page = doc.pages.first;
        final raw = (await page.loadText())!;
        final scale = 1800 / page.width;
        final image = (await page.render(
          fullWidth: 1800,
          fullHeight: page.height * scale,
        ))!;
        try {
          final text = <ChartText>[];
          for (
            var i = 0;
            i < raw.fullText.length && i < raw.charRects.length;
            i++
          ) {
            final r = raw.charRects[i].rotate(page.rotation.index, page);
            if (raw.fullText[i] == '\n' ||
                raw.fullText[i] == '\r' ||
                r.width <= 0 ||
                r.height <= 0) {
              continue;
            }
            text.add(
              ChartText(
                raw.fullText[i],
                Rect.fromLTRB(
                  r.left * scale,
                  (page.height - r.top) * scale,
                  r.right * scale,
                  (page.height - r.bottom) * scale,
                ),
              ),
            );
          }
          final result = parseFlowchartPages([
            FlowchartPage(image.width, image.height, image.pixels, text),
          ]);
          expect(result.courses.length, 40);
          expect(
            result.courses.fold<int>(0, (s, c) => s + (c.credits ?? 0)),
            120,
          );
          expect(
            result.courses.singleWhere((c) => c.id == 'CSC 1350').semester,
            1,
          );
          expect(
            result.links.any((l) => l.from == 'CSC 1350' && l.to == 'CSC 1351'),
            true,
          );
        } finally {
          image.dispose();
        }
      } finally {
        await doc.dispose();
      }
    },
    skip: Platform.environment['PDFIUM_PATH'] == null
        ? 'Set PDFIUM_PATH to run the native PDF engine check.'
        : false,
  );
}
