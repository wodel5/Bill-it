import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final String fileName;

  UpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.fileName,
  });
}

enum UpdateSource { github, gitee }

class UpdateService {
  static const _sourceKey = 'updateSource';
  static const _skippedKey = 'skippedVersion';
  static const _githubOwner = 'wodel5';
  static const _githubRepo = 'Bill-it';
  static const _giteeOwner = 'wodel-five';
  static const _giteeRepo = 'Bill-it';

  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 5),
  ));

  static CancelToken? _cancelToken;
  static CancelToken? _checkCancelToken;
  static final ValueNotifier<double> downloadProgress = ValueNotifier(0);
  static final ValueNotifier<String> downloadStatus = ValueNotifier('');
  static bool isDownloading = false;

  static Future<UpdateSource> getSource() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_sourceKey);
    if (value == 'github') return UpdateSource.github;
    return UpdateSource.gitee;
  }

  static Future<void> setSource(UpdateSource source) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sourceKey, source.name);
  }

  static String _apiUrl(UpdateSource source) {
    switch (source) {
      case UpdateSource.github:
        return 'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest';
      case UpdateSource.gitee:
        return 'https://gitee.com/api/v5/repos/$_giteeOwner/$_giteeRepo/releases/latest';
    }
  }

  static Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  static void cancelCheck() {
    _checkCancelToken?.cancel();
    _checkCancelToken = null;
  }

  static Future<UpdateInfo?> checkUpdate({UpdateSource? source}) async {
    final src = source ?? await getSource();
    final url = _apiUrl(src);
    cancelCheck();
    _checkCancelToken = CancelToken();
    try {
      final response = await _dio.get(url, cancelToken: _checkCancelToken);
      final data = response.data;
      final tagName = data['tag_name'] as String? ?? '';
      final version = tagName.replaceFirst('v', '');
      final assets = data['assets'] as List<dynamic>? ?? [];
      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        if (name.endsWith('.apk')) {
          final downloadUrl = asset['browser_download_url'] as String? ?? '';
          if (downloadUrl.isNotEmpty) {
            return UpdateInfo(
              latestVersion: version,
              downloadUrl: downloadUrl,
              fileName: name,
            );
          }
        }
      }
      return null;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return null;
      rethrow;
    }
  }

  static Future<bool> hasUpdate({UpdateSource? source}) async {
    final info = await checkUpdate(source: source);
    if (info == null) return false;
    final current = await getCurrentVersion();
    return compareVersion(info.latestVersion, current);
  }

  static bool compareVersion(String latest, String current) {
    final l = latest.split('.').map(int.tryParse).toList();
    final c = current.split('.').map(int.tryParse).toList();
    for (var i = 0; i < 3; i++) {
      final lv = (i < l.length ? l[i] : 0) ?? 0;
      final cv = (i < c.length ? c[i] : 0) ?? 0;
      if (lv > cv) return true;
      if (lv < cv) return false;
    }
    return false;
  }

  static void cancelDownload() {
    _cancelToken?.cancel();
    _cancelToken = null;
    isDownloading = false;
    downloadProgress.value = 0;
    downloadStatus.value = '';
  }

  static Future<String?> downloadApk(String url) async {
    _cancelToken = CancelToken();
    isDownloading = true;
    downloadProgress.value = 0;
    downloadStatus.value = '正在连接...';

    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/app_update.apk.zip';
    try {
      await _dio.download(
        url,
        filePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final p = received / total;
            downloadProgress.value = p;
            downloadStatus.value = '正在下载 ${(p * 100).toStringAsFixed(0)}%';
          } else {
            downloadStatus.value = '正在下载...';
          }
        },
      );
      final apkPath = '${dir.path}/app_update.apk';
      final file = File(filePath);
      if (await file.exists()) {
        await file.rename(apkPath);
      }
      isDownloading = false;
      downloadProgress.value = 1.0;
      downloadStatus.value = '下载完成，正在安装...';
      return apkPath;
    } on DioException catch (e) {
      isDownloading = false;
      if (e.type == DioExceptionType.cancel) {
        downloadStatus.value = '已取消';
        return null;
      }
      rethrow;
    } catch (_) {
      isDownloading = false;
      rethrow;
    }
  }

  static Future<void> installApk(String filePath) async {
    const channel = MethodChannel('update/install');
    try {
      await channel.invokeMethod('install', {'path': filePath});
    } catch (_) {
      rethrow;
    }
  }

  static Future<String?> getSkippedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_skippedKey);
  }

  static Future<void> skipVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_skippedKey, version);
  }

  static Future<void> clearSkippedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_skippedKey);
  }

  static final ValueNotifier<bool> hasNewVersion = ValueNotifier(false);
  static String? latestVersion;

  static Future<void> silentCheck() async {
    try {
      final info = await checkUpdate();
      if (info != null && compareVersion(info.latestVersion, await getCurrentVersion())) {
        latestVersion = info.latestVersion;
        hasNewVersion.value = true;
      } else {
        hasNewVersion.value = false;
      }
    } catch (_) {
      hasNewVersion.value = false;
    }
  }
}
