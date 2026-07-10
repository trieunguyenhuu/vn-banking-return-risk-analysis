-- A1. Kiểm tra NULL trong fact_price_daily
SELECT dc.symbol,
       COUNT(*) FILTER (WHERE f.close_price IS NULL) AS null_close,
       COUNT(*) FILTER (WHERE f.volume IS NULL)      AS null_volume
FROM fact_price_daily f
JOIN dim_company dc ON dc.company_id = f.company_id
GROUP BY dc.symbol;
-- Không mã nào null close_price hay volume

-- A2. Kiểm tra NULL trong fact_financial_quarterly
SELECT dc.symbol,
       COUNT(*) FILTER (WHERE f.ratio_value IS NULL) AS null_ratio
FROM fact_financial_quarterly f
JOIN dim_company dc ON dc.company_id = f.company_id
GROUP BY dc.symbol;
-- Không mã nào null null_ratio

-- B1. Kiểm tra trùng (company_id, trade_date) trong fact_price_daily
SELECT company_id, trade_date, COUNT(*)
FROM fact_price_daily
GROUP BY company_id, trade_date
HAVING COUNT(*) > 1;
-- Không có dòng nào trùng

-- B2. Kiểm tra trùng (company_id, year, quarter, ratio_id) trong fact_financial_quarterly
SELECT company_id, year, quarter, ratio_id, COUNT(*)
FROM fact_financial_quarterly
GROUP BY company_id, year, quarter, ratio_id
HAVING COUNT(*) > 1;
-- Không có dòng nào trùng

-- C1. Tìm khoảng cách giữa 2 ngày giao dịch liên tiếp cho từng mã
-- Khoảng cách (gap) > 4 ngày thường là nghỉ lễ (VD: Tết Nguyên Đán ~7-9 ngày) -> bình thường
-- Nếu có khoảng cách bất thường giữa tuần (không trùng dịp lễ) -> nghi vấn thiếu dữ liệu
WITH gaps AS (
    SELECT dc.symbol, f.trade_date,
           LAG(f.trade_date) OVER (PARTITION BY f.company_id ORDER BY f.trade_date) AS prev_date
    FROM fact_price_daily f
    JOIN dim_company dc ON dc.company_id = f.company_id
)
SELECT symbol, prev_date, trade_date, (trade_date - prev_date) AS gap_days
FROM gaps
WHERE (trade_date - prev_date) > 4
ORDER BY gap_days DESC;

-- D1. Giá hoặc volume am (không hợp lệ về mặt nghiệp vụ)
SELECT * FROM fact_price_daily
WHERE open_price < 0 OR high_price < 0 OR low_price < 0 OR close_price < 0 OR volume < 0;
-- Không có dòng nào có giá hoặc volume âm

-- D2. Logic OHLC: high phải là giá cao nhất, low phải là giá thấp nhất trong ngày
SELECT * FROM fact_price_daily
WHERE high_price < GREATEST(open_price, close_price, low_price)
   OR low_price  > LEAST(open_price, close_price, high_price);
-- Không có dòng nào vi phạm logic OHLC

-- E1. Số dòng giá mỗi mã - đối chiếu với log fetch (kỳ vọng ~625 dòng/mã)
SELECT dc.symbol, COUNT(*) AS n_rows
FROM fact_price_daily f
JOIN dim_company dc ON dc.company_id = f.company_id
GROUP BY dc.symbol
ORDER BY n_rows;
-- Đủ 625 dòng mỗi mã

-- E2. Số quý tài chính mỗi mã
SELECT dc.symbol, COUNT(DISTINCT (year, quarter)) AS n_quarters
FROM fact_financial_quarterly f
JOIN dim_company dc ON dc.company_id = f.company_id
GROUP BY dc.symbol;
-- 3 quý, Q1/2026, Q4/2025, Q3/2025