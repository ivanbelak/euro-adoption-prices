import sys
from pathlib import Path

import numpy as np
import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))

from event_study import empirical_p, placebo_steps, step_effect  # noqa: E402

ADOPTION = pd.Timestamp("2015-01-01")


def synthetic_index(jump: float, trend_per_month: float) -> pd.DataFrame:
    """Control: steady inflation plus a tourist-season wave. Adopter: the same,
    plus its own linear trend, plus a one-off jump at adoption."""
    months = pd.date_range("2000-01-01", "2020-12-01", freq="MS")
    t = np.arange(len(months))
    season = 1.5 * np.sin(2 * np.pi * months.month / 12)
    control = 100 + 0.2 * t + season
    adopter = control + trend_per_month * t + jump * (months >= ADOPTION)
    return pd.DataFrame({("XX", "SERV"): adopter, ("CC", "SERV"): control}, index=months)


def test_step_recovers_a_one_off_jump_despite_a_pre_trend():
    idx = synthetic_index(jump=2.0, trend_per_month=0.05)
    step = step_effect(idx, "XX", "CC", "SERV", ADOPTION, window=24)
    # The jump is in index points of the original series; rebasing to the
    # month before (~136) scales it by 100/136, the trend is removed exactly.
    base = idx.loc[ADOPTION - pd.DateOffset(months=1), ("XX", "SERV")]
    assert abs(step - 2.0 * 100 / base) < 0.05


def test_placebo_dates_find_no_effect_where_there_is_none():
    idx = synthetic_index(jump=2.0, trend_per_month=0.05)
    placebo = placebo_steps(idx, "XX", ADOPTION, "CC", "SERV", min_gap=18, max_gap=120)
    assert len(placebo) > 90
    assert placebo["step"].abs().max() < 0.05


def test_missing_data_gives_nan_not_an_error():
    idx = synthetic_index(jump=2.0, trend_per_month=0.0)
    idx.loc[:"2014-06-01", ("XX", "SERV")] = np.nan
    assert np.isnan(step_effect(idx, "XX", "CC", "SERV", ADOPTION))


def test_empirical_p():
    placebo = pd.Series([0.1, -0.2, 0.5, 3.0])
    assert empirical_p(1.0, placebo) == (1 + 1) / (1 + 4)
