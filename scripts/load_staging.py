from sqlalchemy import create_engine
from dotenv import load_dotenv
from pathlib import Path
import pandas as pd
import glob
import os

env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(dotenv_path=env_path)

DB_USER = os.getenv("DB_USER")
DB_PASS = os.getenv("DB_PASS")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")

engine = create_engine(f"postgresql+psycopg2://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}")

BASE_DIR = Path(__file__).resolve().parent.parent
RAW_DIR = BASE_DIR / "raw"

# 1. Nap staging_price_raw (10 ma co phieu)
price_files = glob.glob(str(RAW_DIR / "price" / "*_price.parquet"))
df_list = []
for f in price_files:
    df = pd.read_parquet(f)
    df_list.append(df)

df_price = pd.concat(df_list, ignore_index=True)
df_price = df_price.rename(columns={
    "time": "trade_time",
    "open": "open_price",
    "high": "high_price",
    "low": "low_price",
    "close": "close_price"
})
df_price = df_price[["symbol", "trade_time", "open_price", "high_price", "low_price", "close_price", "volume"]]

df_price.to_sql("staging_price_raw", engine, if_exists="append", index=False)
print(f"Da nap {len(df_price)} dong vao staging_price_raw (co phieu)")

# 2. Nap VNINDEX vao staging_price_raw
df_index = pd.read_parquet(RAW_DIR / "index" / "VNINDEX_price.parquet")
df_index = df_index.rename(columns={
    "time": "trade_time", "open": "open_price", "high": "high_price",
    "low": "low_price", "close": "close_price"
})
df_index["symbol"] = "VNINDEX"   # file goc khong co cot symbol, tu them
df_index = df_index[["symbol", "trade_time", "open_price", "high_price", "low_price", "close_price", "volume"]]

df_index.to_sql("staging_price_raw", engine, if_exists="append", index=False)
print(f"Da nap {len(df_index)} dong vao staging_price_raw (VNINDEX)")

# 3. Nap staging_financial_raw
fin_files = glob.glob(str(RAW_DIR / "financial" / "*_ratio.parquet"))
rows = []
for f in fin_files:
    df = pd.read_parquet(f)
    symbol = df["symbol"].iloc[0]
    quarter_cols = [c for c in df.columns if c not in ("item", "item_id", "symbol")]
    for _, row in df.iterrows():
        for q in quarter_cols:
            rows.append({
                "symbol": symbol,
                "item": row["item"],
                "item_id": row["item_id"],
                "quarter_label": q,
                "value": row[q]
            })

df_fin = pd.DataFrame(rows)
df_fin.to_sql("staging_financial_raw", engine, if_exists="append", index=False)
print(f"Da nap {len(df_fin)} dong vao staging_financial_raw")