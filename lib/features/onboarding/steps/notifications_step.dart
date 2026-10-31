import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/settings/settings_providers.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/onboarding/onboarding_controller.dart';
import 'package:prosoche/features/onboarding/onboarding_platform.dart';
import 'package:prosoche/features/onboarding/onboarding_screen.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

/// O4 Notifikacie (docs/02 A1, docs/01 5.1). Systemovy
/// dialog sa ukaze az po tapnuti na "Allow notifications" (vysvetlenie je
/// na obrazovke pred nim). Po navrate zo systemovych nastaveni (resumed)
/// sa stav povoleni nacita znova.
class NotificationsStep extends ConsumerStatefulWidget {
  const NotificationsStep({required this.onNext, super.key});

  final OnboardingNext onNext;

  @override
  ConsumerState<NotificationsStep> createState() => _NotificationsStepState();
}

class _NotificationsStepState extends ConsumerState<NotificationsStep> {
  late final AppLifecycleListener _lifecycle;
  NotificationAccess? _access;
  bool _denied = false;
  bool _requesting = false;
  bool _busy = false;

  // Nastavenia (zapisu sa pri Continue).
  bool? _morning;
  bool? _evening;
  bool? _private;
  String _morningTime = SettingsKeys.notifMorningTime.defaultValue;
  String _eveningTime = SettingsKeys.notifEveningTime.defaultValue;

  OnboardingNotifications get _platform =>
      ref.read(onboardingNotificationsProvider);

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
    unawaited(_refresh());
    unawaited(_loadSettings());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final access = await _platform.access();
    if (mounted) setState(() => _access = access);
  }

  Future<void> _loadSettings() async {
    final s = ref.read(settingsRepositoryProvider);
    final morning = await s.get(SettingsKeys.notifMorningEnabled);
    final private = await s.get(SettingsKeys.notifPrivateLockscreen);
    final time = await s.get(SettingsKeys.notifMorningTime);
    final evening = await s.get(SettingsKeys.notifEveningEnabled);
    final eveningTime = await s.get(SettingsKeys.notifEveningTime);
    if (!mounted) return;
    setState(() {
      _morning ??= morning;
      _evening ??= evening;
      _private ??= private;
      _morningTime = time;
      _eveningTime = eveningTime;
    });
  }

  Future<void> _requestPermission() async {
    setState(() => _requesting = true);
    final granted = await _platform.requestPermission();
    ref.read(onboardingControllerProvider).track('permission_result', {
      'permission': 'notifications',
      'granted': granted,
    });
    await _refresh();
    if (mounted) {
      setState(() {
        _requesting = false;
        _denied = !granted;
      });
    }
  }

  Future<void> _continue() async {
    setState(() => _busy = true);
    try {
      final s = ref.read(settingsRepositoryProvider);
      if (_morning != null) {
        await s.set(SettingsKeys.notifMorningEnabled, _morning!);
      }
      if (_evening != null) {
        await s.set(SettingsKeys.notifEveningEnabled, _evening!);
      }
      if (_private != null) {
        await s.set(SettingsKeys.notifPrivateLockscreen, _private!);
      }
      ref.read(onboardingControllerProvider).notificationsGranted =
          _access?.enabled ?? false;
      await widget.onNext();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _format(BuildContext context, String hhmm) {
    final [h, m] = hhmm.split(':').map(int.parse).toList();
    return ProsocheFormats(Localizations.localeOf(context))
        .time(DateTime(2000, 1, 1, h, m));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.sk.text;
    final access = _access;
    final loaded = access != null && _morning != null;

    final Widget permission;
    if (access == null) {
      permission = const SkSkeletonBox(height: SkSpace.minTouchTarget);
    } else if (access.enabled) {
      permission = Row(
        children: [
          Icon(Icons.check_circle_outline, color: context.sk.colors.success),
          const SizedBox(width: SkSpace.space8),
          Expanded(child: Text(l10n.onbNotifOn, style: text.bodyLarge)),
        ],
      );
    } else if (_denied) {
      permission = SkInlineBanner(
        variant: SkBannerVariant.warning,
        message: l10n.onbNotifDenied,
        actionLabel: l10n.onbOpenSettings,
        onAction: _platform.openAppSettings,
      );
    } else {
      permission = SkButton.secondary(
        label: l10n.onbNotifAllow,
        icon: Icons.notifications_outlined,
        loading: _requesting,
        expand: true,
        onPressed: _requesting ? null : _requestPermission,
      );
    }

    return OnboardingStepBody(
      icon: Icons.notifications_none,
      title: l10n.onbNotifTitle,
      body: l10n.onbNotifBody,
      primaryLabel: l10n.onbContinue,
      busy: _busy,
      onPrimary: loaded ? _continue : null,
      children: [
        SwitchListTile(
          key: const ValueKey('notif:morning'),
          contentPadding: EdgeInsetsDirectional.zero,
          title: Text(l10n.onbNotifMorning(_format(context, _morningTime))),
          value: _morning ?? true,
          onChanged: (v) => setState(() => _morning = v),
        ),
        // Vecerna reflexia: opt-in, default vypnute (I-01).
        SwitchListTile(
          key: const ValueKey('notif:evening'),
          contentPadding: EdgeInsetsDirectional.zero,
          title: Text(l10n.onbNotifEvening(_format(context, _eveningTime))),
          subtitle: Text(l10n.onbNotifEveningHelp),
          value: _evening ?? false,
          onChanged: (v) => setState(() => _evening = v),
        ),
        SwitchListTile(
          key: const ValueKey('notif:private'),
          contentPadding: EdgeInsetsDirectional.zero,
          title: Text(l10n.onbNotifPrivate),
          value: _private ?? true,
          onChanged: (v) => setState(() => _private = v),
        ),
        const SizedBox(height: SkSpace.space16),
        permission,
      ],
    );
  }
}
