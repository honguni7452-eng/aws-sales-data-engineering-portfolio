"""Lab1 sales_data.csv 품질 검사."""

from pathlib import Path

import pandas as pd


DATA_PATH = Path(__file__).resolve().parents[1] / "data" / "sales_data.csv"


def main() -> None:
    sales = pd.read_csv(DATA_PATH, parse_dates=["order_date"])

    checks = {
        "행 수가 10,000개": len(sales) == 10_000,
        "order_id 중복 없음": not sales["order_id"].duplicated().any(),
        "결측치 없음": not sales.isna().any().any(),
        "customer_id 범위 1~1,000": sales["customer_id"].between(1, 1_000).all(),
        "product_id 범위 1~50": sales["product_id"].between(1, 50).all(),
        "amount 범위 10~500": sales["amount"].between(10, 500).all(),
        "주문일 범위 90일 이내": (
            sales["order_date"].max() - sales["order_date"].min()
        ).days <= 89,
    }

    for name, passed in checks.items():
        print(f"[{'PASS' if passed else 'FAIL'}] {name}")

    if not all(checks.values()):
        raise ValueError("데이터 품질 검사에 실패했습니다.")


if __name__ == "__main__":
    main()
