/// Расширение для String: конвертирует Google Drive share-URL в direct-URL.
extension GoogleDriveLink on String {
  /// Если this содержит `/d/FILE_ID` или `?id=FILE_ID`,
  /// возвращает `https://drive.google.com/uc?export=view&id=FILE_ID`.
  /// Иначе — возвращает исходную строку без изменений.
  String toDriveDirect() {
    final reg = RegExp(r'/d/([^/]+)|[?&]id=([^&]+)');
    final m = reg.firstMatch(this);
    final id = m?.group(1) ?? m?.group(2);
    if (id != null && id.isNotEmpty) {
      return 'https://drive.google.com/uc?export=view&id=$id';
    }
    return this;
  }
}
