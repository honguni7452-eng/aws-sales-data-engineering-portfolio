"""Lab1 판매 데이터 10,000행 생성.

실행 위치와 관계없이 Lab1/data/sales_data.csv에 저장한다.
"""

from pathlib import Path

import numpy as np
import pandas as pd


ROW_COUNT = 10_000
RANDOM_SEED = 42
OUTPUT_PATH = Path(__file__).resolve().parents[1] / "data" / "sales_data.csv"


def create_sales_data(row_count: int = ROW_COUNT) -> pd.DataFrame:
    """재현 가능한 판매 샘플 데이터를 생성한다."""
    rng = np.random.default_rng(RANDOM_SEED)
    today = pd.Timestamp.today().normalize()

    return pd.DataFrame(
        {
            "order_id": np.arange(1, row_count + 1),
            "customer_id": rng.integers(1, 1_001, size=row_count),
            "product_id": rng.integers(1, 51, size=row_count),
            "amount": np.round(rng.uniform(10, 500, size=row_count), 2),
            "order_date": today - pd.to_timedelta(
                rng.integers(0, 90, size=row_count), unit="D"
            ),
        }
    )


def main() -> None:
    sales = create_sales_data()
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    sales.to_csv(OUTPUT_PATH, index=False, date_format="%Y-%m-%d")

    print(f"저장 경로: {OUTPUT_PATH}")
    print(f"생성 행 수: {len(sales):,}")
    print(sales.head())


if __name__ == "__main__":
    main()
