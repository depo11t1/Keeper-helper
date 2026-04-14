import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class SpiderAvatar extends StatelessWidget {
  const SpiderAvatar({
    super.key,
    required this.accent,
    this.seed = -1,
    this.label,
    this.size = 68,
    this.photoPath,
  });

  final Color accent;
  final int seed;
  final String? label;
  final double size;
  final String? photoPath;
  static final Map<String, ImageProvider> _imageCache = {};

  static String thumbnailPath(String photoPath) => '$photoPath.thumb.png';

  static String resolvePhotoPath(String photoPath) {
    final thumb = File(thumbnailPath(photoPath));
    return thumb.existsSync() ? thumb.path : photoPath;
  }

  static ImageProvider _providerFor(String path) {
    return _imageCache[path] ?? FileImage(File(path));
  }

  static void cacheBytesForPath(
    BuildContext context,
    String path,
    List<int> bytes,
    List<double> sizes,
  ) {
    _imageCache[path] = MemoryImage(Uint8List.fromList(bytes));
  }

  static Future<Uint8List?> createThumbnailBytes(
    List<int> bytes, {
    int targetSize = 384,
  }) async {
    try {
      final codec =
          await ui.instantiateImageCodec(bytes, targetWidth: targetSize);
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  static Future<String?> ensureThumbnail(String photoPath) async {
    final thumbPath = thumbnailPath(photoPath);
    final thumbFile = File(thumbPath);
    if (thumbFile.existsSync()) {
      return thumbPath;
    }
    final source = File(photoPath);
    if (!source.existsSync()) {
      return null;
    }
    try {
      final bytes = await source.readAsBytes();
      final thumbBytes = await createThumbnailBytes(bytes);
      if (thumbBytes == null) {
        return null;
      }
      await thumbFile.writeAsBytes(thumbBytes, flush: true);
      return thumbPath;
    } catch (_) {
      return null;
    }
  }

  static Future<void> precacheForSizes(
    BuildContext context,
    String path,
    List<double> sizes,
  ) async {
    final provider = _providerFor(path);
    await precacheImage(provider, context);
  }

  @override
  Widget build(BuildContext context) {
    final hasPreview = seed >= 0;
    final hasPhoto = photoPath != null && File(photoPath!).existsSync();
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final cacheSize = (size * dpr).round();
    final resolvedPath = hasPhoto ? resolvePhotoPath(photoPath!) : null;
    final photoProvider =
        resolvedPath == null ? null : _providerFor(resolvedPath);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        color: hasPreview
            ? accent.withValues(alpha: 0.12)
            : accent.withValues(alpha: 0.10),
      ),
      child: Center(
        child: hasPhoto
            ? ClipRRect(
                borderRadius: BorderRadius.circular(size * 0.26),
                child: Image(
                  image: photoProvider!,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                  isAntiAlias: true,
                  cacheWidth: cacheSize,
                ),
              )
            : hasPreview
                ? Icon(
                    Icons.photo_size_select_actual_rounded,
                    color: Colors.white.withValues(alpha: 0.88),
                    size: size * 0.38,
                  )
                : Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Colors.white.withValues(alpha: 0.82),
                    size: size * 0.40,
                  ),
      ),
    );
  }
}
