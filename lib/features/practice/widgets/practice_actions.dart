import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/quests/quests.dart';

/// Pouzivatel potvrdil, ze cvicenie urobil: splni `act` quest dna
/// (self report, plan 7.2). Opakovane potvrdenie nic nemeni.
Future<void> confirmPracticeDone(WidgetRef ref) async {
  final date = await ref.read(activeSetDateProvider.future);
  final quests = ref.read(questsProvider(date)).value ?? const <QuestView>[];
  final act = quests.where((q) => q.slot == QuestSlot.act).firstOrNull;
  if (act?.status == QuestStatus.done) return;
  await ref.read(questRepositoryProvider).setActStatus(date, QuestStatus.done);
  unawaited(HapticFeedback.lightImpact());
}
