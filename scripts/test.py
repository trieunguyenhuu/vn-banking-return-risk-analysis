from sqlalchemy import create_engine
from dotenv import load_dotenv
from pathlib import Path
import pandas as pd
import numpy as np
import os

env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(dotenv_path=env_path)

DB_USER = os.getenv("DB_USER")
DB_PASS = os.getenv("DB_PASS")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")

engine = create_engine(f"postgresql+psycopg2://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}")

symbol = "VCB"  # doi ma muon kiem tra

df = pd.read_sql(f"""
    SELECT trade_date, close_price FROM fact_price_daily p
    JOIN dim_company c USING (company_id) WHERE c.symbol = '{symbol}' ORDER BY trade_date
""", engine)
df["daily_return"] = df["close_price"].pct_change()

idx = pd.read_sql("""
    SELECT trade_date, close_price FROM fact_price_daily p
    JOIN dim_company c USING (company_id) WHERE c.is_index = TRUE ORDER BY trade_date
""", engine)
idx["market_return"] = idx["close_price"].pct_change()
merged = df.merge(idx[["trade_date", "market_return"]], on="trade_date")

print("Volatility 20d (tinh doc lap):", merged["daily_return"].tail(20).std() * np.sqrt(252))
last60 = merged.tail(60)
print("Beta 60d (tinh doc lap, numpy.polyfit):", np.polyfit(last60["market_return"], last60["daily_return"], 1)[0])

sql_check = pd.read_sql(f"""
    SELECT trade_date, volatility_20d_annualized, beta_60d FROM v_metric_layer
    WHERE symbol = '{symbol}' ORDER BY trade_date DESC LIMIT 1
""", engine)
print(sql_check)