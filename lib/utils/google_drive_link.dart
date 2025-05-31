// lib/utils/google_drive_link.dart
extension DriveLinkFix on String {
  /// Google Drive share-URL → прямой user-content URL.
  /// 1) https://drive.google.com/file/d/FILE_ID/view?usp=sharing
  ///    → https://lh3.googleusercontent.com/d/FILE_ID
  ///
  /// 2) если строка не похожа на Google Drive — возвращаем как есть.
  String toDriveDirect() {
    final m = RegExp(r'/d/([^/]+)/').firstMatch(this);
    final id = m?.group(1);
    return id == null
        ? this
        : 'https://lh3.googleusercontent.com/d/$id';
  }
}
