-- 1. DAILY RETURN
CREATE OR REPLACE VIEW v_daily_return AS
WITH price_lag AS (
    SELECT
        p.company_id, c.symbol, c.is_index, p.trade_date, p.close_price,
        ROW_NUMBER() OVER (PARTITION BY p.company_id ORDER BY p.trade_date) AS rn,
        LAG(p.close_price) OVER (PARTITION BY p.company_id ORDER BY p.trade_date) AS prev_close_price
    FROM fact_price_daily p
    JOIN dim_company c ON c.company_id = p.company_id
)
SELECT company_id, symbol, is_index, trade_date, close_price, rn,
    (close_price - prev_close_price) / NULLIF(prev_close_price, 0) AS daily_return
FROM price_lag;

-- 2. ROLLING VOLATILITY 20 NGAY
CREATE OR REPLACE VIEW v_volatility_20d AS
SELECT company_id, symbol, trade_date, daily_return,
    CASE WHEN rn >= 20 THEN
        STDDEV_SAMP(daily_return) OVER (
            PARTITION BY company_id ORDER BY trade_date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
        ) * SQRT(252)
    ELSE NULL END AS volatility_20d_annualized
FROM v_daily_return;

-- 3. BETA 60 NGAY SO VOI VN-INDEX
CREATE OR REPLACE VIEW v_beta_60d AS
WITH market_return AS (
    SELECT trade_date, daily_return AS market_return FROM v_daily_return WHERE is_index = TRUE
),
stock_market AS (
    SELECT r.company_id, r.symbol, r.trade_date, r.rn,
        r.daily_return AS stock_return, m.market_return
    FROM v_daily_return r
    JOIN market_return m ON m.trade_date = r.trade_date
    WHERE r.is_index = FALSE
)
SELECT company_id, symbol, trade_date,
    CASE WHEN rn >= 60 THEN
        REGR_SLOPE(stock_return, market_return) OVER (
            PARTITION BY company_id ORDER BY trade_date ROWS BETWEEN 59 PRECEDING AND CURRENT ROW
        )
    ELSE NULL END AS beta_60d
FROM stock_market;

-- 4. MOVING AVERAGE 50 / 200 NGAY
CREATE OR REPLACE VIEW v_moving_average AS
SELECT p.company_id, c.symbol, p.trade_date, p.close_price,
    CASE WHEN ROW_NUMBER() OVER (PARTITION BY p.company_id ORDER BY p.trade_date) >= 50 THEN
        AVG(p.close_price) OVER (PARTITION BY p.company_id ORDER BY p.trade_date ROWS BETWEEN 49 PRECEDING AND CURRENT ROW)
    ELSE NULL END AS ma_50,
    CASE WHEN ROW_NUMBER() OVER (PARTITION BY p.company_id ORDER BY p.trade_date) >= 200 THEN
        AVG(p.close_price) OVER (PARTITION BY p.company_id ORDER BY p.trade_date ROWS BETWEEN 199 PRECEDING AND CURRENT ROW)
    ELSE NULL END AS ma_200
FROM fact_price_daily p
JOIN dim_company c ON c.company_id = p.company_id;

-- 5. METRIC LAYER TONG HOP
CREATE OR REPLACE VIEW v_metric_layer AS
SELECT r.company_id, r.symbol, r.trade_date, r.close_price, r.daily_return,
    v.volatility_20d_annualized, b.beta_60d, m.ma_50, m.ma_200
FROM v_daily_return r
LEFT JOIN v_volatility_20d v USING (company_id, trade_date)
LEFT JOIN v_beta_60d b USING (company_id, trade_date)
LEFT JOIN v_moving_average m USING (company_id, trade_date)
WHERE r.is_index = FALSE;