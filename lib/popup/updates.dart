import 'package:flutter/material.dart';
import '../services/update_service.dart';

void showDownloadDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      content: const _DownloadDialog(),
    ),
  );
}

Future<void> showUpdateDialog(BuildContext context) async {
  final source = await UpdateService.getSource();
  final currentVersion = await UpdateService.getCurrentVersion();
  if (!context.mounted) return;

  UpdateSource selectedSource = source;

  showDialog(
    context: context,
    builder: (ctx) => _UpdateCheckDialog(
      currentVersion: currentVersion,
      selectedSource: selectedSource,
      onSourceChanged: (s) => selectedSource = s,
    ),
  );
}

class _UpdateCheckDialog extends StatefulWidget {
  final String currentVersion;
  final UpdateSource selectedSource;
  final ValueChanged<UpdateSource> onSourceChanged;

  const _UpdateCheckDialog({
    required this.currentVersion,
    required this.selectedSource,
    required this.onSourceChanged,
  });

  @override
  State<_UpdateCheckDialog> createState() => _UpdateCheckDialogState();
}

class _UpdateCheckDialogState extends State<_UpdateCheckDialog> {
  late UpdateSource _source;
  bool _checking = false;
  UpdateInfo? _updateInfo;
  bool _checked = false;
  bool _checkFailed = false;

  @override
  void initState() {
    super.initState();
    _source = widget.selectedSource;
    _check();
  }

  int _checkGeneration = 0;

  Future<void> _check() async {
    final gen = ++_checkGeneration;
    setState(() {
      _checking = true;
      _updateInfo = null;
      _checked = false;
      _checkFailed = false;
    });
    try {
      final info = await UpdateService.checkUpdate(source: _source);
      if (!mounted || gen != _checkGeneration) return;
      setState(() {
        _checking = false;
        _checked = true;
        if (info != null && UpdateService.compareVersion(info.latestVersion, widget.currentVersion)) {
          _updateInfo = info;
        }
      });
    } catch (_) {
      if (!mounted || gen != _checkGeneration) return;
      setState(() {
        _checking = false;
        _checked = true;
        _checkFailed = true;
      });
    }
  }

  Future<void> _download() async {
    if (_updateInfo == null) return;
    final downloadUrl = _updateInfo!.downloadUrl;

    if (!UpdateService.isDownloading) {
      UpdateService.downloadApk(downloadUrl).then((path) async {
        if (path != null) {
          await UpdateService.installApk(path);
        }
      }).catchError((e) {});
    }

    Navigator.pop(context);
    await Future.delayed(const Duration(milliseconds: 100));
    if (context.mounted) {
      showDownloadDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLatest = _updateInfo == null && _checked && !_checkFailed;
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.loop,
            color: _checking
                ? Theme.of(context).primaryColor
                : _checkFailed
                    ? Theme.of(context).colorScheme.secondary
                    : isLatest
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).colorScheme.tertiary,
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text('检查更新', style: TextStyle(fontSize: 18)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('更新源:', style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              )),
              const SizedBox(width: 12),
              _sourceChip('Gitee', UpdateSource.gitee),
              const SizedBox(width: 8),
              _sourceChip('GitHub', UpdateSource.github),
            ],
          ),
          const SizedBox(height: 16),
          Text('当前版本: ${widget.currentVersion}',
              style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          if (_checking)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('正在检查...', style: TextStyle(fontSize: 14)),
              ],
            )
          else if (_checkFailed)
            Text(
              '检查失败，请检查网络后重试',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            )
          else if (isLatest)
            Text(
              '已是最新版本',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            )
          else if (_updateInfo != null)
            Text(
              '发现新版本: ${_updateInfo!.latestVersion}',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.tertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  if (_updateInfo != null) {
                    await UpdateService.skipVersion(_updateInfo!.latestVersion);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.grey.withValues(alpha: 0.12),
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide.none,
                ),
                child: const Text('取消', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _updateInfo != null ? _download : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('下载更新',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sourceChip(String label, UpdateSource value) {
    final selected = _source == value;
    return GestureDetector(
      onTap: () {
          setState(() => _source = value);
          UpdateService.setSource(value);
              widget.onSourceChanged(value);
              _check();
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).primaryColor
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected
                ? Colors.white
                : Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }
}

class _DownloadDialog extends StatelessWidget {
  const _DownloadDialog();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.loop, color: Theme.of(context).primaryColor, size: 24),
            const SizedBox(width: 8),
            const Text('正在下载', style: TextStyle(fontSize: 18)),
          ],
        ),
        const SizedBox(height: 20),
        ValueListenableBuilder<double>(
          valueListenable: UpdateService.downloadProgress,
          builder: (_, progress, __) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: UpdateService.isDownloading ? (progress > 0 ? progress : null) : 1.0,
                  minHeight: 10,
                  backgroundColor: Theme.of(context).dividerColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ValueListenableBuilder<String>(
                    valueListenable: UpdateService.downloadStatus,
                    builder: (_, status, __) => Text(
                      status,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  UpdateService.cancelDownload();
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.grey.withValues(alpha: 0.12),
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide.none,
                ),
                child: const Text('取消下载', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide.none,
                ),
                child: Text('后台下载',
                    style: TextStyle(fontSize: 16, color: Theme.of(context).primaryColor)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
