class UpdateInfo {
  final String version;
  final int versionCode;
  final String downloadUrl;
  final String releaseNotes;
  final bool forceUpdate;

  UpdateInfo({
    required this.version,
    required this.versionCode,
    required this.downloadUrl,
    required this.releaseNotes,
    this.forceUpdate = false,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] ?? '',
      versionCode: json['versionCode'] ?? 0,
      downloadUrl: json['downloadUrl'] ?? '',
      releaseNotes: json['releaseNotes'] ?? '',
      forceUpdate: json['forceUpdate'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'versionCode': versionCode,
      'downloadUrl': downloadUrl,
      'releaseNotes': releaseNotes,
      'forceUpdate': forceUpdate,
    };
  }
}
