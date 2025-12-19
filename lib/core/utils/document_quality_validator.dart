import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

class DocumentQualityResult {
  final bool isValid;
  final String? errorMessage;
  final double qualityScore;
  final bool hasText;
  final bool isSharp;
  final bool isWellLit;

  DocumentQualityResult({
    required this.isValid,
    this.errorMessage,
    required this.qualityScore,
    required this.hasText,
    required this.isSharp,
    required this.isWellLit,
  });
}

class DocumentQualityValidator {
  static final TextRecognizer _textRecognizer = TextRecognizer();

  /// Validates document image quality
  static Future<DocumentQualityResult> validateDocument(File imageFile) async {
    try {
      // Load and analyze the image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        return DocumentQualityResult(
          isValid: false,
          errorMessage: 'Unable to read image file',
          qualityScore: 0.0,
          hasText: false,
          isSharp: false,
          isWellLit: false,
        );
      }

      // 1. Check image size (should be reasonable resolution)
      final isGoodSize = image.width >= 400 && image.height >= 300;
      if (!isGoodSize) {
        return DocumentQualityResult(
          isValid: false,
          errorMessage: 'Image resolution too low. Please retake with better quality',
          qualityScore: 0.2,
          hasText: false,
          isSharp: false,
          isWellLit: false,
        );
      }

      // 2. Check brightness/lighting
      final brightness = _calculateBrightness(image);
      final isWellLit = brightness > 30 && brightness < 220;

      if (!isWellLit) {
        String lightingError = brightness <= 30
            ? 'Image is too dark. Please use better lighting'
            : 'Image is overexposed. Reduce lighting or avoid flash';

        return DocumentQualityResult(
          isValid: false,
          errorMessage: lightingError,
          qualityScore: 0.3,
          hasText: false,
          isSharp: false,
          isWellLit: false,
        );
      }

      // 3. Check blur/sharpness using Laplacian variance
      final sharpness = _calculateSharpness(image);
      final isSharp = sharpness > 100; // Threshold for acceptable sharpness

      if (!isSharp) {
        return DocumentQualityResult(
          isValid: false,
          errorMessage: 'Image is blurry. Hold camera steady and retake',
          qualityScore: 0.5,
          hasText: false,
          isSharp: false,
          isWellLit: isWellLit,
        );
      }

      // 4. Check if text is detected (using ML Kit)
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final hasText = recognizedText.text.trim().isNotEmpty;
      final textBlocks = recognizedText.blocks.length;

      if (!hasText || textBlocks < 2) {
        return DocumentQualityResult(
          isValid: false,
          errorMessage: 'No text detected. Ensure document is clear and visible',
          qualityScore: 0.6,
          hasText: false,
          isSharp: isSharp,
          isWellLit: isWellLit,
        );
      }

      // Calculate overall quality score
      double qualityScore = 0.0;
      qualityScore += isWellLit ? 0.25 : 0.0;
      qualityScore += isSharp ? 0.35 : 0.0;
      qualityScore += hasText ? 0.25 : 0.0;
      qualityScore += (textBlocks >= 5) ? 0.15 : 0.1;

      // All checks passed
      return DocumentQualityResult(
        isValid: true,
        errorMessage: null,
        qualityScore: qualityScore,
        hasText: true,
        isSharp: true,
        isWellLit: true,
      );

    } catch (e) {
      debugPrint('Error validating document: $e');
      return DocumentQualityResult(
        isValid: false,
        errorMessage: 'Error analyzing image. Please try again',
        qualityScore: 0.0,
        hasText: false,
        isSharp: false,
        isWellLit: false,
      );
    }
  }

  /// Calculate average brightness of the image
  static double _calculateBrightness(img.Image image) {
    int totalBrightness = 0;
    int pixelCount = 0;

    // Sample pixels (not all for performance)
    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        // Calculate luminance
        final brightness = (0.299 * r + 0.587 * g + 0.114 * b);
        totalBrightness += brightness.toInt();
        pixelCount++;
      }
    }

    return totalBrightness / pixelCount;
  }

  /// Calculate sharpness using Laplacian variance (blur detection)
  static double _calculateSharpness(img.Image image) {
    // Convert to grayscale
    final gray = img.grayscale(image);

    // Calculate Laplacian variance (higher = sharper)
    double variance = 0;
    int count = 0;

    // Sample the image for performance
    for (int y = 1; y < gray.height - 1; y += 5) {
      for (int x = 1; x < gray.width - 1; x += 5) {
        final center = gray.getPixel(x, y).r.toInt();
        final top = gray.getPixel(x, y - 1).r.toInt();
        final bottom = gray.getPixel(x, y + 1).r.toInt();
        final left = gray.getPixel(x - 1, y).r.toInt();
        final right = gray.getPixel(x + 1, y).r.toInt();

        // Laplacian kernel
        final laplacian = (4 * center - top - bottom - left - right).abs();
        variance += laplacian * laplacian;
        count++;
      }
    }

    return variance / count;
  }

  /// Dispose the text recognizer
  static void dispose() {
    _textRecognizer.close();
  }
}
