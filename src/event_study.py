"""Event study in Python, so it can be run for any adoption date.

The SQL views (sql/05, sql/07) compute the event study for the real euro
adoption dates. A placebo test needs the same calculation for many *fake*
dates, which is easier here. The method is identical:

1. Rebase adopter and control prices to 100 in the month before adoption.
2. excess = adopter - control, for months -window .. +11.
3. Fit a straight line through excess over months -window .. -1 and
   subtract it (the pre-existing trend).
4. step = mean trend-adjusted excess over months 0..11
          - mean trend-adjusted excess over months -12..-1

For the real dates the results match the SQL views (see the notebook).
"""

from __future__ import annotations

import numpy as np
import pandas as pd

PEERS = ["HU", "PL", "CZ", "RO"]


def load_index(conn, countries: list[str], categories: list[str]) -> pd.DataFrame:
    """Monthly price index (2015 = 100), one column per (country, category)."""
    marks = ", ".join("?" * len(countries))
    cmarks = ", ".join("?" * len(categories))
    sql = (f"SELECT country_code, coicop_code, month_date, index_2015 "
           f"FROM fact.hicp_monthly "
           f"WHERE country_code IN ({marks}) AND coicop_code IN ({cmarks})")
    rows = conn.cursor().execute(sql, *countries, *categories).fetchall()
    df = pd.DataFrame.from_records(
        [tuple(r) for r in rows], columns=["country", "coicop", "month", "index"])
    df["month"] = pd.to_datetime(df["month"])
    df["index"] = df["index"].astype(float)
    wide = df.pivot_table(index="month", columns=["country", "coicop"], values="index")
    # An index of exactly 0 (e.g. free kindergartens) makes growth undefined
    return wide.replace(0.0, np.nan).asfreq("MS")


def _rebased(series: pd.Series, t0: pd.Timestamp, window: int) -> pd.Series | None:
    """Series on event months -window..11, rebased to 100 at month -1."""
    dates = pd.date_range(t0 - pd.DateOffset(months=window), periods=window + 12, freq="MS")
    base_date = t0 - pd.DateOffset(months=1)
    if base_date not in series.index or pd.isna(series.get(base_date)):
        return None
    values = series.reindex(dates) / series[base_date] * 100.0
    values.index = np.arange(-window, 12)
    return values


def control_series(idx: pd.DataFrame, control: str, coicop: str,
                   t0: pd.Timestamp, window: int) -> pd.Series | None:
    """Rebased control. 'PEERS' = average of the rebased peers, only where all have data."""
    if control != "PEERS":
        if (control, coicop) not in idx:
            return None
        return _rebased(idx[(control, coicop)], t0, window)
    parts = []
    for peer in PEERS:
        if (peer, coicop) not in idx:
            return None
        s = _rebased(idx[(peer, coicop)], t0, window)
        if s is None:
            return None
        parts.append(s)
    peers = pd.concat(parts, axis=1)
    return peers.mean(axis=1).where(peers.notna().all(axis=1))


def step_effect(idx: pd.DataFrame, adopter: str, control: str, coicop: str,
                t0: pd.Timestamp, window: int = 24) -> float:
    """Trend-adjusted step: first year after t0 vs the year before. NaN if data is missing."""
    if (adopter, coicop) not in idx:
        return np.nan
    a = _rebased(idx[(adopter, coicop)], t0, window)
    c = control_series(idx, control, coicop, t0, window)
    if a is None or c is None:
        return np.nan
    excess = a - c

    pre = excess.loc[-window:-1].dropna()
    if len(pre) < 0.75 * window:          # same rule as sql/07
        return np.nan
    slope = np.polyfit(pre.index.to_numpy(float), pre.to_numpy(float), 1)[0]
    detrended = excess - slope * (excess.index + 1)

    after = detrended.loc[0:11].dropna()
    before = detrended.loc[-12:-1].dropna()
    if len(after) < 10 or len(before) < 10:
        return np.nan
    return float(after.mean() - before.mean())


def placebo_steps(idx: pd.DataFrame, adopter: str, adoption: pd.Timestamp,
                  control: str, coicop: str, window: int = 24,
                  min_gap: int = 18, max_gap: int = 240) -> pd.DataFrame:
    """Step effect for fake adoption dates 'min_gap'..'max_gap' months before the real one.

    min_gap = 18 keeps the fake year after adoption (months 0..11) clear of the
    six months before the real changeover, when prices were already shown in
    euros and anticipation could leak in.
    """
    rows = []
    for gap in range(min_gap, max_gap + 1):
        t0 = adoption - pd.DateOffset(months=gap)
        step = step_effect(idx, adopter, control, coicop, t0, window)
        if not np.isnan(step):
            rows.append({"adopter": adopter, "control": control, "coicop": coicop,
                         "months_before_real": gap, "fake_date": t0, "step": step})
    return pd.DataFrame(rows)


def empirical_p(real: float, placebo: pd.Series) -> float:
    """Share of placebo steps at least as large as the real one (one-sided).

    The +1 in numerator and denominator counts the real estimate as one of the
    draws, so p is never exactly 0 with a finite number of placebos.
    """
    placebo = placebo.dropna()
    return (1 + int((placebo >= real).sum())) / (1 + len(placebo))
