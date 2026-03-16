// File: lib/roles/partially_sighted/home/sections/home_screen/widgets/map_marker_helper.dart


import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MapMarkerHelper {
  static Future<Uint8List?> createProfileMarker({
    required String? imageUrl,
    required String name,
    required Color borderColor,
    double size = 120.0,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(size / 2, size / 2 + 4), size / 2 - 8, shadowPaint);

      // Draw white border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 5, borderPaint);

      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(imageUrl)).timeout(Duration(seconds: 5));
          if (response.statusCode == 200) {
            final codec = await ui.instantiateImageCodec(
              response.bodyBytes,
              targetWidth: size.toInt() - 20,
              targetHeight: size.toInt() - 20,
            );
            final frame = await codec.getNextFrame();
            
            // Clip to circle
            final path = Path()
              ..addOval(Rect.fromCircle(
                center: Offset(size / 2, size / 2),
                radius: size / 2 - 10,
              ));
            canvas.clipPath(path);
            
            // Draw image
            canvas.drawImageRect(
              frame.image,
              Rect.fromLTWH(0, 0, frame.image.width.toDouble(), frame.image.height.toDouble()),
              Rect.fromCircle(center: Offset(size / 2, size / 2), radius: size / 2 - 10),
              Paint(),
            );
          } else {
            _drawDefaultAvatar(canvas, size, name, borderColor);
          }
        } catch (e) {
          _drawDefaultAvatar(canvas, size, name, borderColor);
        }
      } else {
        _drawDefaultAvatar(canvas, size, name, borderColor);
      }

      // Draw colored border
      final coloredBorderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 7, coloredBorderPaint);

      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error creating marker: $e');
      return null;
    }
  }

  static void _drawDefaultAvatar(Canvas canvas, double size, String name, Color color) {
    // Draw gradient background
    final rect = Rect.fromCircle(center: Offset(size / 2, size / 2), radius: size / 2 - 10);
    final gradient = ui.Gradient.linear(
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.bottom),
      [color, color.withValues(alpha: 0.7)],
    );
    final paint = Paint()..shader = gradient;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 10, paint);

    // Draw initial
    final textPainter = TextPainter(
      text: TextSpan(
        text: name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size / 2 - textPainter.width / 2,
        size / 2 - textPainter.height / 2,
      ),
    );
  }
}