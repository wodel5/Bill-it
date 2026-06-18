// lib/popup/updates.dart
import 'package:flutter/material.dart';

/// 更新进度弹窗 - 显示下载进度
class UpdateProgressDialog extends StatefulWidget {
  final double progress;
  final String status;

  const UpdateProgressDialog({
    super.key,
    required this.progress,
    required this.status,
  });

  @override
  _UpdateProgressDialogState createState() => _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends State<UpdateProgressDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '正在更新',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(
              value: widget.progress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 16),
            Text(
              widget.status,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.progress.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

/// 更新结果对话框 - 显示检查结果
class UpdateResultDialog extends StatelessWidget {
  final bool isSuccess;
  final String message;
  final String? currentVersion;
  final String? latestVersion;
  final VoidCallback? onRetry;

  const UpdateResultDialog({
    super.key,
    required this.isSuccess,
    required this.message,
    this.currentVersion,
    this.latestVersion,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error_outline,
            color: isSuccess ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Text(isSuccess ? '检查完成' : '检查失败'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (currentVersion != null && latestVersion != null) ...[
            const SizedBox(height: 12),
            Text('当前版本: $currentVersion'),
            Text('最新版本: $latestVersion'),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
