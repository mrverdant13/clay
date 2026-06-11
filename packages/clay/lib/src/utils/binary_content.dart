import 'package:path/path.dart' as p;

/// File extensions copied to output without text transforms.
const binaryContentExtensions = {
  '.png',
  '.webp',
  '.jpg',
  '.jpeg',
  '.gif',
  '.ico',
  '.jar',
  '.keystore',
  '.p12',
  '.jks',
};

/// Basenames copied to output without text transforms.
const binaryContentBasenames = {'.DS_Store'};

/// Whether [path] should bypass the annotation transform pipeline.
bool shouldSkipBinaryContent(String path) {
  if (binaryContentBasenames.contains(p.basename(path))) {
    return true;
  }
  return binaryContentExtensions.contains(
    p.extension(path).toLowerCase(),
  );
}
