"""Lab1 데이터에 중복 500행과 오류 500행을 추가한다."""

from pathlib import Path

import numpy as np
import pandas as pd


LAB2_ROOT = Path(__file__).resolve().parents[1]
INPUT_PATH = LAB2_ROOT.parent / "Lab1" / "data" / "sales_data.csv"
OUTPUT_PATH = LAB2_ROOT / "data" / "sales2" / "sales.csv"
RANDOM_SEED = 42
DUPLICATE_COUNT = 500
INVALID_COUNT = 500
NULL_CUSTOMER_COUNT = 165
NEGATIVE_AMOUNT_COUNT = 164
FUTURE_DATE_COUNT = 171


def create_dirty_data(source: pd.DataFrame) -> tuple[pd.DataFrame, dict[str, int]]:
    """정상 데이터에 완전 중복과 세 종류의 오류 행을 추가한다."""
    rng = np.random.default_rng(RANDOM_SEED)
    source = source.copy()
    source["order_date"] = pd.to_datetime(source["order_date"])

    duplicate_rows = source.sample(
        n=DUPLICATE_COUNT, random_state=RANDOM_SEED
    ).copy()

    invalid_rows = source.sample(
        n=INVALID_COUNT, random_state=RANDOM_SEED + 1
    ).copy()
    invalid_rows["order_id"] = np.arange(
        int(source["order_id"].max()) + 1,
        int(source["order_id"].max()) + INVALID_COUNT + 1,
    )
    invalid_rows["customer_id"] = invalid_rows["customer_id"].astype("Int64")

    issue_types = np.array(
        ["null_customer"] * NULL_CUSTOMER_COUNT
        + ["negative_amount"] * NEGATIVE_AMOUNT_COUNT
        + ["future_date"] * FUTURE_DATE_COUNT
    )
    rng.shuffle(issue_types)

    null_mask = issue_types == "null_customer"
    negative_mask = issue_types == "negative_amount"
    future_mask = issue_types == "future_date"

    invalid_rows.loc[null_mask, "customer_id"] = pd.NA
    invalid_rows.loc[negative_mask, "amount"] = -invalid_rows.loc[
        negative_mask, "amount"
    ].abs()
    invalid_rows.loc[future_mask, "order_date"] = invalid_rows.loc[
        future_mask, "order_date"
    ] + pd.DateOffset(years=10)

    dirty = pd.concat([source, duplicate_rows, invalid_rows], ignore_index=True)
    dirty = dirty.sample(frac=1, random_state=RANDOM_SEED).reset_index(drop=True)

    issue_counts = {
        "duplicate_rows": DUPLICATE_COUNT,
        "null_customer_id": int(null_mask.sum()),
        "negative_amount": int(negative_mask.sum()),
        "future_date": int(future_mask.sum()),
    }
    return dirty, issue_counts


def main() -> None:
    source = pd.read_csv(INPUT_PATH)
    dirty, issue_counts = create_dirty_data(source)

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    dirty.to_csv(OUTPUT_PATH, index=False, date_format="%Y-%m-%d")

    print(f"입력 파일: {INPUT_PATH}")
    print(f"기존 데이터 수: {len(source):,}개")
    print(f"중복 행: {issue_counts['duplicate_rows']:,}개")
    print(f"customer_id NULL: {issue_counts['null_customer_id']:,}개")
    print(f"amount 음수: {issue_counts['negative_amount']:,}개")
    print(f"10년 뒤 날짜: {issue_counts['future_date']:,}개")
    print(f"오류 유형 합계: {sum(issue_counts.values()) - DUPLICATE_COUNT:,}개")
    print(f"최종 데이터 수: {len(dirty):,}개")
    print(f"저장 경로: {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
