// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class L10nZh extends L10n {
  L10nZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Skylink SSH';

  @override
  String get serverPreview => '服务器预览';

  @override
  String get addServer => '添加服务器';

  @override
  String get connect => '连接';

  @override
  String get disconnect => '断开连接';

  @override
  String get terminal => '终端';

  @override
  String get fileManager => '文件管理';

  @override
  String get monitoring => '监控';

  @override
  String get aiAssistant => 'AI助手';

  @override
  String get settings => '设置';

  @override
  String get serverName => '服务器名称';

  @override
  String get hostname => '主机名';

  @override
  String get port => '端口';

  @override
  String get username => '用户名';

  @override
  String get password => '密码';

  @override
  String get privateKey => '私钥';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get cpuUsage => 'CPU使用率';

  @override
  String get memoryUsage => '内存使用率';

  @override
  String get diskUsage => '磁盘使用率';

  @override
  String get loadAverage => '负载平均值';

  @override
  String get networkUpload => '上传';

  @override
  String get networkDownload => '下载';

  @override
  String get shutdown => '关机';

  @override
  String get restart => '重启';

  @override
  String get theme => '主题';

  @override
  String get language => '语言';

  @override
  String get about => '关于';
}
