import 'package:go_router/go_router.dart';
import 'package:prosoche/core/router/routes.dart';
import 'package:prosoche/domain/practice/practice.dart';
import 'package:prosoche/features/practice/exercise_screen.dart';
import 'package:prosoche/features/practice/journal_screen.dart';
import 'package:prosoche/features/practice/memento_mori_screen.dart';
import 'package:prosoche/features/practice/practice_screen.dart';
import 'package:prosoche/features/practice/routine_screen.dart';

/// Cesty Practice (F-01).
abstract final class PracticeRoutes {
  static const String root = AppRoutes.practice;
  static const journal = '$root/journal';
  static const memento = '$root/memento';

  static const routineName = 'practice_routine';
  static const journalName = 'journal';
  static const mementoName = 'memento_mori';
  static const exerciseName = 'exercise';

  /// `/practice/routine/morning|evening`.
  static String routine(RoutineKind kind) => '$root/routine/${kind.tag}';

  /// `/practice/exercise/<kluc za practice:>`.
  static String exercise(String key) => '$root/exercise/$key';

  static RoutineKind? parseRoutine(String? raw) =>
      RoutineKind.values.where((k) => k.tag == raw).firstOrNull;
}

/// Tab Practice (PLAN.md kap. 2). Vlastnik: F-01.
List<RouteBase> practiceRoutes() => [
  GoRoute(
    path: AppRoutes.practice,
    name: AppRouteNames.practice,
    builder: (context, state) => const PracticeScreen(),
    routes: [
      GoRoute(
        path: 'routine/:kind',
        name: PracticeRoutes.routineName,
        redirect: (context, state) =>
            PracticeRoutes.parseRoutine(state.pathParameters['kind']) == null
            ? PracticeRoutes.root
            : null,
        builder: (context, state) => RoutineScreen(
          kind: PracticeRoutes.parseRoutine(state.pathParameters['kind'])!,
        ),
      ),
      GoRoute(
        path: 'journal',
        name: PracticeRoutes.journalName,
        builder: (context, state) => const JournalScreen(),
      ),
      GoRoute(
        path: 'memento',
        name: PracticeRoutes.mementoName,
        builder: (context, state) => const MementoMoriScreen(),
      ),
      GoRoute(
        path: 'exercise/:key',
        name: PracticeRoutes.exerciseName,
        builder: (context, state) =>
            ExerciseScreen(cardKey: state.pathParameters['key']!),
      ),
    ],
  ),
];
