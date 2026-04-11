import 'package:universal_io/io.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageProcessor {
  static const int targetSize = 512;

  static Future<Uint8List> processToWebp512FromBytes(Uint8List imageBytes) async {
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('이미지를 디코딩할 수 없습니다');
    }

    final int size = image.width > image.height ? image.height : image.width;
    final int offsetX = (image.width - size) ~/ 2;
    final int offsetY = (image.height - size) ~/ 2;

    img.Image croppedImage = img.copyCrop(
      image,
      x: offsetX,
      y: offsetY,
      width: size,
      height: size,
    );

    img.Image resizedImage = img.copyResize(
      croppedImage,
      width: targetSize,
      height: targetSize,
      interpolation: img.Interpolation.cubic,
    );

    final Uint8List webpBytes = Uint8List.fromList(
      img.encodeJpg(resizedImage, quality: 90),
    );

    return webpBytes;
  }

  static Future<Uint8List> processToWebp512(String imagePath) async {
    final File imageFile = File(imagePath);
    final Uint8List imageBytes = await imageFile.readAsBytes();

    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('이미지를 디코딩할 수 없습니다');
    }

    final int size = image.width > image.height ? image.height : image.width;
    final int offsetX = (image.width - size) ~/ 2;
    final int offsetY = (image.height - size) ~/ 2;

    img.Image croppedImage = img.copyCrop(
      image,
      x: offsetX,
      y: offsetY,
      width: size,
      height: size,
    );

    img.Image resizedImage = img.copyResize(
      croppedImage,
      width: targetSize,
      height: targetSize,
      interpolation: img.Interpolation.cubic,
    );

    final Uint8List webpBytes = Uint8List.fromList(
      img.encodeJpg(resizedImage, quality: 90),
    );

    return webpBytes;
  }
}
