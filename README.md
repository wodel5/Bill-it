# 报账了吗

一款简洁的 Flutter 记账报销 App，支持记录日常开销、分类管理、报账状态追踪。

## 功能

- **记账管理** — 添加、编辑、删除消费记录，支持滑动操作
- **回收站** — 删除的记录存入回收站，可恢复或彻底删除
- **分类标签** — 自定义分类，每个分类可设置颜色，按分类筛选
- **报账状态** — 标记已报账/未报账，底部汇总栏直观展示金额
- **置顶** — 重要记录一键置顶
- **搜索** — 按用途、报销人搜索记录
- **排序** — 支持按时间、金额、用途拼音排序
- **深色模式** — 跟随系统 / 浅色 / 深色 三种主题切换
- **本地存储** — 基于 SharedPreferences，无需网络

## 截图

<p align="center">
  <img src="images/screenshots/1.png" width="45%" />
  <img src="images/screenshots/2.png" width="45%" />
</p>

## 技术栈

- Flutter 3.x + Dart
- Provider 状态管理
- SharedPreferences 本地持久化
- flutter_slidable 滑动操作
- intl 国际化（中/英）

## 运行

```bash
flutter pub get
flutter run
```
