import gzip
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))

from fetch_eurostat import tsv_to_long  # noqa: E402


def test_tsv_to_long_parses_values_flags_and_missing(tmp_path):
    tsv = (
        "freq,unit,coicop18,geo\\TIME_PERIOD\t2023-01 \t2023-02 \t2023-03 \n"
        "M,I15,TOTAL,HR\t101.5 \t102.25 p\t: \n"
        "M,I15,CP01,HR\t: u\t-0.4 \t99 d\n"
    )
    src = tmp_path / "sample.tsv.gz"
    with gzip.open(src, "wt", encoding="utf-8") as f:
        f.write(tsv)

    df = tsv_to_long(src)

    assert len(df) == 4  # the two missing cells (":" and ": u") are dropped
    assert df["value"].notna().all()
    row = df[(df.coicop == "TOTAL") & (df.date == "2023-02-01")].iloc[0]
    assert row.value == 102.25 and row.flag == "p"
    assert df[(df.coicop == "CP01") & (df.date == "2023-02-01")].value.iloc[0] == -0.4
    assert df[df.flag == "d"].value.iloc[0] == 99
