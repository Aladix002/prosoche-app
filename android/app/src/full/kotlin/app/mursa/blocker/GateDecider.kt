package app.mursa.blocker

/** Co monitor vie o nastaveniach v case ticku. */
class BlockerSnapshot(
    val enabled: Boolean,
    val blocked: Set<String>,
    val isUnlocked: (String) -> Boolean,
)

sealed interface GateDecision {
    data class ShowGate(val ref: String) : GateDecision

    data class Skip(val reason: SkipReason) : GateDecision
}

enum class SkipReason {
    DISABLED,
    UNKNOWN_FOREGROUND,
    OWN_APP,
    NOT_BLOCKED,
    UNLOCKED,
    ALREADY_GATED,
}

/**
 * Rozhodovacia logika monitora (TECHNICKY_PLAN 9.2 body 1-3), bez Androidu.
 *
 * Brana sa pre jednu appku v popredi spusti len raz ([gatedFor]), aby
 * neuspesny start brany (napr. BAL obmedzenie) nezacyklil spustanie kazdu
 * sekundu. Stav sa vynuluje, ked:
 * - je v popredi Mursa (brana sa zobrazila; navrat do appky cez recents
 *   bez odomknutia znova ukaze branu),
 * - je v popredi neblokovana appka (home, ina appka),
 * - je appka odomknuta (po vyprsani odomknutia pocas pouzivania sa brana
 *   ukaze znova).
 */
class GateDecider(private val ownPackage: String) {
    private var gatedFor: String? = null

    fun decide(foreground: String?, snapshot: BlockerSnapshot): GateDecision {
        if (!snapshot.enabled) {
            gatedFor = null
            return GateDecision.Skip(SkipReason.DISABLED)
        }
        if (foreground == null) return GateDecision.Skip(SkipReason.UNKNOWN_FOREGROUND)
        if (foreground == ownPackage) {
            gatedFor = null
            return GateDecision.Skip(SkipReason.OWN_APP)
        }
        if (foreground !in snapshot.blocked) {
            gatedFor = null
            return GateDecision.Skip(SkipReason.NOT_BLOCKED)
        }
        if (snapshot.isUnlocked(foreground)) {
            gatedFor = null
            return GateDecision.Skip(SkipReason.UNLOCKED)
        }
        if (gatedFor == foreground) return GateDecision.Skip(SkipReason.ALREADY_GATED)
        gatedFor = foreground
        return GateDecision.ShowGate(foreground)
    }
}
