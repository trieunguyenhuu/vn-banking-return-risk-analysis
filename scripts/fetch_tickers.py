from vnstock import Quote, Finance
from pathlib import Path
import pandas as pd
import time
import os

TICKERS = ["VCB", "BID", "CTG", "TCB", "ACB", "MBB", "VPB", "HDB", "STB", "VIB"]
START_DATE = "2024-01-02"
END_DATE = "2026-07-09"

BASE_DIR = Path(__file__).resolve().parent.parent
RAW_DIR = BASE_DIR / "raw"

os.makedirs(RAW_DIR / "price", exist_ok=True)
os.makedirs(RAW_DIR / "financial", exist_ok=True)
os.makedirs(RAW_DIR / "index", exist_ok=True)

# 1. Gia + khoi luong hang ngay
price_summary = []
for symbol in TICKERS:
    try:
        quote = Quote(symbol=symbol, source="KBS")
        df = quote.history(start=START_DATE, end=END_DATE, interval="1D")
        df["symbol"] = symbol
        df.to_parquet(RAW_DIR / "price" / f"{symbol}_price.parquet", index=False)
        price_summary.append((symbol, len(df), "OK"))
    except Exception as e:
        price_summary.append((symbol, 0, f"LOI: {e}"))
    time.sleep(3)

# 2. Chi so tai chinh quy
financial_summary = []
for symbol in TICKERS:
    try:
        finance = Finance(symbol=symbol, source="KBS")
        df = finance.ratio(period="quarter")
        df["symbol"] = symbol
        df.to_parquet(RAW_DIR / "financial" / f"{symbol}_ratio.parquet", index=False)
        n_quarters = len([c for c in df.columns if c not in ("item", "item_id", "symbol")])
        financial_summary.append((symbol, n_quarters, "OK"))
    except Exception as e:
        financial_summary.append((symbol, 0, f"LOI: {e}"))
    time.sleep(3)

# 3. VN-Index
quote_index = Quote(symbol="VNINDEX", source="KBS")
df_index = quote_index.history(start=START_DATE, end=END_DATE, interval="1D")
df_index.to_parquet(RAW_DIR / "index" / "VNINDEX_price.parquet", index=False)

# 4. Bao cao tong hop
print("=== GIA & KHOI LUONG ===")
for s, n, status in price_summary:
    print(f"{s:6s}  {n:4d} dong   {status}")

print("\n=== CHI SO TAI CHINH QUY ===")
for s, n, status in financial_summary:
    print(f"{s:6s}  {n} quy   {status}")

print(f"\nVN-Index: {len(df_index)} dong")