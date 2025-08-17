import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/index.dart';
import '../models/index.dart';
import '../theme/index.dart';
import '../widgets/app_bar_custom.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../widgets/ai_config_dialog.dart';
import '../widgets/sync_config_dialog.dart';
import '../widgets/theme_selector.dart';
import '../widgets/language_selector.dart';
import '../widgets/confirmation_dialog.dart';

/// Settings Screen - Application configuration and preferences
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState;
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider);
    final aiConfig = ref.watch(aiConfigProvider);
    final syncConfig = ref.watch(syncConfigProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBarCustom(
        title: l10n.settings,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
            onPressed: _isLoading ? null : () async {
              setState(() => _isLoading = true);
              try {
                await ref.read(appSettingsNotifierProvider.notifier).refresh();
                await ref.read(aiConfigNotifierProvider.notifier).refresh();
                await ref.read(syncConfigNotifierProvider.notifier).refresh();
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Appearance Section
                SettingsSection(
                  title: l10n.appearance,
                  icon: Icons.palette_rounded,
                  children: [
                    SettingsTile(
                      title: l10n.theme,
                      subtitle: _getThemeLabel(settings.themeMode, l10n),
                      leading: Icon(
                        _getThemeIcon(settings.themeMode),
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                      onTap: () => _showThemeSelector(context, settings.themeMode),
                    ),
                    SettingsTile(
                      title: l10n.language,
                      subtitle: _getLanguageLabel(settings.locale, l10n),
                      leading: Icon(
                        Icons.language_rounded,
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                      onTap: () => _showLanguageSelector(context, settings.locale),
                    ),
                    SettingsTile(
                      title: l10n.compactMode,
                      subtitle: l10n.compactModeDescription,
                      leading: Icon(
                        Icons.view_compact_rounded,
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                      trailing: Switch(
                        value: settings.compactMode,
                        onChanged: (value) {
                          ref.read(appSettingsNotifierProvider.notifier)
                              .updateSettings(settings.copyWith(compactMode: value));
                        },
                        activeColor: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Connection Section
                SettingsSection(
                  title: l10n.connection,
                  icon: Icons.link_rounded,
                  children: [
                    SettingsTile(
                      title: l10n.autoConnect,
                      subtitle: l10n.autoConnectDescription,
                      leading: Icon(
                        Icons.autorenew_rounded,
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                      trailing: Switch(
                        value: settings.autoConnect,
                        onChanged: (value) {
                          ref.read(appSettingsNotifierProvider.notifier)
                              .updateSettings(settings.copyWith(autoConnect: value));
                        },
                        activeColor: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                    ),
                    SettingsTile(
                      title: l10n.connectionTimeout,
                      subtitle: '${settings.connectionTimeout}${l10n.seconds}',
                      leading: Icon(
                        Icons.timer_rounded,
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                      onTap: () => _showTimeoutDialog(context, settings.connectionTimeout),
                    ),
                    SettingsTile(
                      title: l10n.keepAlive,
                      subtitle: l10n.keepAliveDescription,
                      leading: Icon(
                        Icons.favorite_rounded,
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                      trailing: Switch(
                        value: settings.keepAlive,
                        onChanged: (value) {
                          ref.read(appSettingsNotifierProvider.notifier)
                              .updateSettings(settings.copyWith(keepAlive: value));
                        },
                        activeColor: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Terminal Section
                SettingsSection(
                  title: l10n.terminal,
                  icon: Icons.terminal_rounded,
                  children: [
                    SettingsTile(
                      title: l10n.fontSize,
                      subtitle: '${settings.terminalFontSize}px',
                      leading: Icon(
                        Icons.text_fields_rounded,
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                      onTap: () => _showFontSizeDialog(context, settings.terminalFontSize),
                    ),
                    SettingsTile(
                      title: l10n.fontFamily,
                      subtitle: settings.terminalFontFamily,
                      leading: Icon(
                        Icons.font_download_rounded,
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                      onTap: () => _showFontFamilyDialog(context, settings.terminalFontFamily),
                    ),
                    SettingsTile(
                      title: l10n.cursorBlink,
                      subtitle: l10n.cursorBlinkDescription,
                      leading: Icon(
                        Icons.cursor_text_rounded,
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                      trailing: Switch(
                        value: settings.terminalCursorBlink,
                        onChanged: (value) {
                          ref.read(appSettingsNotifierProvider.notifier)
                              .updateSettings(settings.copyWith(terminalCursorBlink: value));
                        },
                        activeColor: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // AI Assistant Section
                SettingsSection(
                  title: l10n.aiAssistant,
                  icon: Icons.smart_toy_rounded,
                  children: [
                    SettingsTile(
                      title: l10n.aiProvider,
                      subtitle: aiConfig.provider.name,
                      leading: Icon(
                        Icons.psychology_rounded,
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                      trailing: Icon(
                        aiConfig.isConfigured ? Icons.check_circle_rounded : Icons.warning_rounded,
                        color: aiConfig.isConfigured ? AppColors.success : AppColors.warning,
                      ),
                      onTap: () => _showAIConfigDialog(context, aiConfig),
                    ),
                    SettingsTile(
                      title: l10n.enableAI,
                      subtitle: l10n.enableAIDescription,
                      leading: Icon(
                        Icons.auto_awesome_rounded,
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                      trailing: Switch(
                        value: settings.enableAI,
                        onChanged: aiConfig.isConfigured ? (value) {
                          ref.read(appSettingsNotifierProvider.notifier)
                              .updateSettings(settings.copyWith(enableAI: value));
                        } : null,
                        activeColor: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                    ),
                    if (settings.enableAI && aiConfig.isConfigured)
                      SettingsTile(
                        title: l10n.aiAutoSuggest,
                        subtitle: l10n.aiAutoSuggestDescription,
                        leading: Icon(
                          Icons.lightbulb_rounded,
                          color: isDark ? AppColors.primaryDark : AppColors.primary,
                        ),
                        trailing: Switch(
                          value: settings.aiAutoSuggest,
                          onChanged: (value) {
                            ref.read(appSettingsNotifierProvider.notifier)
                                .updateSettings(settings.copyWith(aiAutoSuggest: value));
                          },
                          activeColor: isDark ? AppColors.primaryDark : AppColors.primary,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Sync Section
                SettingsSection(
                  title: l10n.sync,
                  icon: Icons.sync_rounded,
                  children: [
                    SettingsTile(
                      title: l10n.webdavSync,
                      subtitle: syncConfig.isConfigured ? l10n.configured : l10n.notConfigured,
                      leading: Icon(
                        Icons.cloud_sync_rounded,
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                      trailing: Icon(
                        syncConfig.isConfigured ? Icons.check_circle_rounded : Icons.warning_rounded,
                        color: syncConfig.isConfigured ? AppColors.success : AppColors.warning,
                      ),
                      onTap: () => _showSyncConfigDialog(context, syncConfig),
                    ),
                    if (syncConfig.isConfigured)
                      SettingsTile(
                        title: l10n.autoSync,
                        subtitle: l10n.autoSyncDescription,
                        leading: Icon(
                          Icons.sync_alt_rounded,
                          color: isDark ? AppColors.primaryDark : AppColors.primary,
                        ),
                        trailing: Switch(
                          value: settings.autoSync,
                          onChanged: (value) {
                            ref.read(appSettingsNotifierProvider.notifier)
                                .updateSettings(settings.copyWith(autoSync: value));
                          },
                          activeColor: isDark ? AppColors.primaryDark : AppColors.primary,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Security Section
                SettingsSection(
                  title: l10n.security,
                  icon: Icons.security_rounded,
                  children: [
                    SettingsTile(
                      title: l10n.biometricAuth,
                      subtitle: l10n.biometricAuthDescription,
                      leading: Icon(
                        Icons.fingerprint_rounded,
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                      trailing: Switch(
                        value: settings.biometricAuth,
                        onChanged: (value) {
                          ref.read(appSettingsNotifierProvider.notifier)
                              .updateSettings(settings.copyWith(biometricAuth: value));
                        },
                        activeColor: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                    ),
                    SettingsTile(
                      title: l10n.autoLock,
                      subtitle: l10n.autoLockDescription,
                      leading: Icon(
                        Icons.lock_clock_rounded,
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                      trailing: Switch(
                        value: settings.autoLock,
                        onChanged: (value) {
                          ref.read(appSettingsNotifierProvider.notifier)
                              .updateSettings(settings.copyWith(autoLock: value));
                        },
                        activeColor: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Data Section
                SettingsSection(
                  title: l10n.data,
                  icon: Icons.storage_rounded,
                  children: [
                    SettingsTile(
                      title: l10n.exportData,
                      subtitle: l10n.exportDataDescription,
                      leading: Icon(
                        Icons.download_rounded,
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                      onTap: () => _exportData(context),
                    ),
                    SettingsTile(
                      title: l10n.importData,
                      subtitle: l10n.importDataDescription,
                      leading: Icon(
                        Icons.upload_rounded,
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                      onTap: () => _importData(context),
                    ),
                    SettingsTile(
                      title: l10n.clearCache,
                      subtitle: l10n.clearCacheDescription,
                      leading: Icon(
                        Icons.clear_all_rounded,
                        color: AppColors.warning,
                      ),
                      onTap: () => _clearCache(context),
                    ),
                    SettingsTile(
                      title: l10n.resetSettings,
                      subtitle: l10n.resetSettingsDescription,
                      leading: Icon(
                        Icons.restore_rounded,
                        color: AppColors.error,
                      ),
                      onTap: () => _resetSettings(context),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // About Section
                SettingsSection(
                  title: l10n.about,
                  icon: Icons.info_rounded,
                  children: [
                    SettingsTile(
                      title: l10n.version,
                      subtitle: '1.0.0+1',
                      leading: Icon(
                        Icons.tag_rounded,
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                    ),
                    SettingsTile(
                      title: l10n.licenses,
                      subtitle: l10n.licensesDescription,
                      leading: Icon(
                        Icons.article_rounded,
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                      onTap: () => showLicensePage(context: context),
                    ),
                    SettingsTile(
                      title: l10n.feedback,
                      subtitle: l10n.feedbackDescription,
                      leading: Icon(
                        Icons.feedback_rounded,
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                      onTap: () => _sendFeedback(context),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
    );
  }
  
  String _getThemeLabel(ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeMode.system:
        return l10n.systemTheme;
      case ThemeMode.light:
        return l10n.lightTheme;
      case ThemeMode.dark:
        return l10n.darkTheme;
    }
  }
  
  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
      case ThemeMode.light:
        return Icons.brightness_high_rounded;
      case ThemeMode.dark:
        return Icons.brightness_low_rounded;
    }
  }
  
  String _getLanguageLabel(String locale, AppLocalizations l10n) {
    switch (locale) {
      case 'en':
        return 'English';
      case 'zh':
        return '中文';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      default:
        return l10n.systemLanguage;
    }
  }
  
  void _showThemeSelector(BuildContext context, ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (context) => ThemeSelector(
        currentMode: currentMode,
        onChanged: (mode) {
          final settings = ref.read(appSettingsProvider);
          ref.read(appSettingsNotifierProvider.notifier)
              .updateSettings(settings.copyWith(themeMode: mode));
          Navigator.pop(context);
        },
      ),
    );
  }
  
  void _showLanguageSelector(BuildContext context, String currentLocale) {
    showDialog(
      context: context,
      builder: (context) => LanguageSelector(
        currentLocale: currentLocale,
        onChanged: (locale) {
          final settings = ref.read(appSettingsProvider);
          ref.read(appSettingsNotifierProvider.notifier)
              .updateSettings(settings.copyWith(locale: locale));
          Navigator.pop(context);
        },
      ),
    );
  }
  
  void _showTimeoutDialog(BuildContext context, int currentTimeout) {
    showDialog(
      context: context,
      builder: (context) {
        int timeout = currentTimeout;
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.connectionTimeout),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${timeout}${AppLocalizations.of(context)!.seconds}'),
                  Slider(
                    value: timeout.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    onChanged: (value) {
                      setState(() => timeout = value.toInt());
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () {
                final settings = ref.read(appSettingsProvider);
                ref.read(appSettingsNotifierProvider.notifier)
                    .updateSettings(settings.copyWith(connectionTimeout: timeout));
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        );
      },
    );
  }
  
  void _showFontSizeDialog(BuildContext context, double currentSize) {
    showDialog(
      context: context,
      builder: (context) {
        double fontSize = currentSize;
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.fontSize),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${fontSize.toInt()}px'),
                  Slider(
                    value: fontSize,
                    min: 10,
                    max: 24,
                    divisions: 14,
                    onChanged: (value) {
                      setState(() => fontSize = value);
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () {
                final settings = ref.read(appSettingsProvider);
                ref.read(appSettingsNotifierProvider.notifier)
                    .updateSettings(settings.copyWith(terminalFontSize: fontSize));
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        );
      },
    );
  }
  
  void _showFontFamilyDialog(BuildContext context, String currentFamily) {
    final fonts = ['JetBrains Mono', 'Fira Code', 'Source Code Pro', 'Consolas', 'Monaco'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.fontFamily),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: fonts.map((font) => RadioListTile<String>(
            title: Text(font),
            value: font,
            groupValue: currentFamily,
            onChanged: (value) {
              if (value != null) {
                final settings = ref.read(appSettingsProvider);
                ref.read(appSettingsNotifierProvider.notifier)
                    .updateSettings(settings.copyWith(terminalFontFamily: value));
                Navigator.pop(context);
              }
            },
          )).toList(),
        ),
      ),
    );
  }
  
  void _showAIConfigDialog(BuildContext context, AIConfig config) {
    showDialog(
      context: context,
      builder: (context) => AIConfigDialog(
        config: config,
        onSaved: (newConfig) {
          ref.read(aiConfigNotifierProvider.notifier).updateConfig(newConfig);
        },
      ),
    );
  }
  
  void _showSyncConfigDialog(BuildContext context, SyncConfig config) {
    showDialog(
      context: context,
      builder: (context) => SyncConfigDialog(
        config: config,
        onSaved: (newConfig) {
          ref.read(syncConfigNotifierProvider.notifier).updateConfig(newConfig);
        },
      ),
    );
  }
  
  void _exportData(BuildContext context) async {
    try {
      setState(() => _isLoading = true);
      await ref.read(syncServiceProvider).exportLocalData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.dataExported),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.exportFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _importData(BuildContext context) async {
    try {
      setState(() => _isLoading = true);
      await ref.read(syncServiceProvider).importLocalData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.dataImported),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.importFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _clearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: AppLocalizations.of(context)!.clearCache,
        content: AppLocalizations.of(context)!.clearCacheConfirmation,
        confirmText: AppLocalizations.of(context)!.clear,
        isDestructive: true,
        onConfirm: () async {
          try {
            await ref.read(storageServiceProvider).clearCache();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.cacheCleared),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.clearCacheFailed),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
      ),
    );
  }
  
  void _resetSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: AppLocalizations.of(context)!.resetSettings,
        content: AppLocalizations.of(context)!.resetSettingsConfirmation,
        confirmText: AppLocalizations.of(context)!.reset,
        isDestructive: true,
        onConfirm: () async {
          try {
            await ref.read(appSettingsNotifierProvider.notifier).resetToDefaults();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.settingsReset),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.resetFailed),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
      ),
    );
  }
  
  void _sendFeedback(BuildContext context) {
    // TODO: Implement feedback functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.featureComingSoon),
        backgroundColor: AppColors.info,
      ),
    );
  }
}