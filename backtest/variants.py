from dataclasses import replace
from sim import BASELINE
UNBLOCK = dict(core_floor_bootstrap=True, sector_cap_first_exempt=True, core_trend_exempt=True)
MOMO = dict(UNBLOCK, rank_mode="dualrs", rr_gate=False)
V = {
    "v3.4": BASELINE,
    "unblock": replace(BASELINE, **UNBLOCK),
    "unblock+mom": replace(BASELINE, **UNBLOCK, rank_mode="momentum"),
    "dualrs": replace(BASELINE, **MOMO),
    "dualrs+hold10": replace(BASELINE, **MOMO, decay_min_hold=10),
    "dualrs+qconf": replace(BASELINE, **MOMO, quadrant_needs_dma=True, quadrant_confirm=2),
    "dualrs+wide": replace(BASELINE, **MOMO, ladder="wide"),
    "dualrs+cool10": replace(BASELINE, **MOMO, reentry_cooldown=10),
    "dualrs+min5": replace(BASELINE, **MOMO, min_score=5.0),
    "dualrs+all": replace(BASELINE, **MOMO, decay_min_hold=10, quadrant_needs_dma=True, quadrant_confirm=2,
                          ladder="wide", reentry_cooldown=10),
}
V.update({
    "unblock+corr80": replace(BASELINE, **UNBLOCK, max_corr=0.80),
    "unblock+corr70": replace(BASELINE, **UNBLOCK, max_corr=0.70),
    "dualrs+corr80": replace(BASELINE, **MOMO, max_corr=0.80),
    "dualrs+corr70": replace(BASELINE, **MOMO, max_corr=0.70),
    "mom+corr70": replace(BASELINE, **UNBLOCK, rank_mode="momentum", rr_gate=False, max_corr=0.70),
})
BARE = dict(rule16=False, quadrant=False, rule10=False, ladder="none")
V.update({
    "unblock+bare": replace(BASELINE, **UNBLOCK, **BARE),
    "unblock+bare-no7": replace(BASELINE, **UNBLOCK, **BARE, rule7=False),
    "dualrs+bare": replace(BASELINE, **MOMO, **BARE),
    "mom+bare": replace(BASELINE, **UNBLOCK, rank_mode="momentum", rr_gate=False, **BARE),
    "unblock+no16": replace(BASELINE, **UNBLOCK, rule16=False),
    "unblock+noquad": replace(BASELINE, **UNBLOCK, quadrant=False),
    "unblock+noladder": replace(BASELINE, **UNBLOCK, ladder="none"),
})
UM = dict(UNBLOCK, rank_mode="momentum")
V.update({
    "um": replace(BASELINE, **UM),
    "um+noquad": replace(BASELINE, **UM, quadrant=False),
    "um+qconf": replace(BASELINE, **UM, quadrant_needs_dma=True, quadrant_confirm=2),
    "um+hold10": replace(BASELINE, **UM, decay_min_hold=10),
    "um+wide": replace(BASELINE, **UM, ladder="wide"),
    "um+corr80": replace(BASELINE, **UM, max_corr=0.80),
    "um+drift": replace(BASELINE, **UM, reward_mode="drift"),
    "um+arbhold": replace(BASELINE, **UM, decay_arbitration=True, arbitration_trail=None),
    "um+cool10": replace(BASELINE, **UM, reentry_cooldown=10),
    "um+no16": replace(BASELINE, **UM, rule16=False),
    "um+noladder": replace(BASELINE, **UM, ladder="none"),
    "um-nop3": replace(BASELINE, core_floor_bootstrap=True, sector_cap_first_exempt=True, rank_mode="momentum"),
})

# ---- FROZEN for the pre-registered test (do not edit after test runs) ----
V35 = replace(BASELINE, name="v3.5", **UM)
