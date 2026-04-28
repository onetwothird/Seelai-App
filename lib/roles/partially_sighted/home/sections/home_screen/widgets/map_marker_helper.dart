import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MapMarkerHelper {
  static Future<Uint8List?> createProfileMarker({
    required String? imageUrl,
    required String name,
    required Color borderColor,
    double size = 65.0,
    bool isOffline = false, // ✅ ADDED: The parameter your MSWD map is looking for!
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // ✅ ADDED: Grayscale filter matrix for offline users
      final paint = Paint();
      if (isOffline) {
        paint.colorFilter = const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]);
      }

      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(imageUrl)).timeout(const Duration(seconds: 5));
          if (response.statusCode == 200) {
            final codec = await ui.instantiateImageCodec(
              response.bodyBytes,
              targetWidth: size.toInt(),
              targetHeight: size.toInt(),
            );
            final frame = await codec.getNextFrame();
            
            // Just clip to a perfect circle, no borders or shadows
            final path = Path()
              ..addOval(Rect.fromCircle(
                center: Offset(size / 2, size / 2),
                radius: size / 2,
              ));
            canvas.clipPath(path);
            
            canvas.drawImageRect(
              frame.image,
              Rect.fromLTWH(0, 0, frame.image.width.toDouble(), frame.image.height.toDouble()),
              Rect.fromCircle(center: Offset(size / 2, size / 2), radius: size / 2),
              paint, // ✅ Applies the black and white filter here if offline
            );
          } else {
            _drawDefaultAvatar(canvas, size, name, borderColor, isOffline);
          }
        } catch (e) {
          _drawDefaultAvatar(canvas, size, name, borderColor, isOffline);
        }
      } else {
        _drawDefaultAvatar(canvas, size, name, borderColor, isOffline);
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error creating marker: $e');
      return null;
    }
  }

  // ✅ ADDED: isOffline parameter to handle default letter avatars
  static void _drawDefaultAvatar(Canvas canvas, double size, String name, Color color, bool isOffline) {
    final rect = Rect.fromCircle(center: Offset(size / 2, size / 2), radius: size / 2);
    
    // If offline, default avatar turns gray instead of its usual color
    final effectiveColor = isOffline ? Colors.grey : color;
    
    final gradient = ui.Gradient.linear(
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.bottom),
      [effectiveColor, effectiveColor.withValues(alpha: 0.7)],
    );
    final paint = Paint()..shader = gradient;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(color: Colors.white, fontSize: size * 0.4, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size / 2 - textPainter.width / 2, size / 2 - textPainter.height / 2));
  }
}