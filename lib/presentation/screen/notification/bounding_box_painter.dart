import 'package:flutter/material.dart';

class BoundingBoxPainter extends CustomPainter {
  final List? predictions;
  final Size imageSize;
  final Size containerSize;

  BoundingBoxPainter({
    required this.predictions,
    required this.imageSize,
    required this.containerSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (predictions == null || predictions!.isEmpty) return;

    // Calculate scale to fit image in container while maintaining aspect ratio
    final imageAspectRatio = imageSize.width / imageSize.height;
    final containerAspectRatio = containerSize.width / containerSize.height;
    
    double scale;
    double offsetX = 0;
    double offsetY = 0;
    
    if (imageAspectRatio > containerAspectRatio) {
      // Image is wider, fit to width
      scale = containerSize.width / imageSize.width;
      offsetY = (containerSize.height - (imageSize.height * scale)) / 2;
    } else {
      // Image is taller, fit to height
      scale = containerSize.height / imageSize.height;
      offsetX = (containerSize.width - (imageSize.width * scale)) / 2;
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    for (var prediction in predictions!) {
      final x = (prediction['x'] as num).toDouble();
      final y = (prediction['y'] as num).toDouble();
      final width = (prediction['width'] as num).toDouble();
      final height = (prediction['height'] as num).toDouble();
      final className = prediction['class'] as String;
      final confidence = (prediction['confidence'] as num).toDouble();

      // Calculate bounding box coordinates (Roboflow uses center x,y)
      final left = ((x - width / 2) * scale) + offsetX;
      final top = ((y - height / 2) * scale) + offsetY;
      final right = ((x + width / 2) * scale) + offsetX;
      final bottom = ((y + height / 2) * scale) + offsetY;

      // Draw rectangle with color for each object
      paint.color = _getColorForClass(className);
      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        paint,
      );

      // Draw label background
      final label = '$className ${(confidence * 100).toStringAsFixed(0)}%';
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 2,
              color: Colors.black,
            ),
          ],
        ),
      );
      textPainter.layout();

      final labelRect = Rect.fromLTWH(
        left,
        top - 24,
        textPainter.width + 8,
        textPainter.height + 4,
      );

      canvas.drawRect(
        labelRect,
        Paint()..color = _getColorForClass(className).withOpacity(0.8),
      );

      // Draw label text
      textPainter.paint(canvas, Offset(left + 4, top - 22));
    }
  }

  Color _getColorForClass(String className) {
    // Generate consistent color for each class
    final hash = className.hashCode;
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.amber,
      Colors.cyan,
      Colors.lime,
    ];
    return colors[hash.abs() % colors.length];
  }

  @override
  bool shouldRepaint(BoundingBoxPainter oldDelegate) {
    return predictions != oldDelegate.predictions ||
        imageSize != oldDelegate.imageSize ||
        containerSize != oldDelegate.containerSize;
  }
}
