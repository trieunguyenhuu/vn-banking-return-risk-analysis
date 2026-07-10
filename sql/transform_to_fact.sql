-- dim_company --
INSERT INTO dim_company (symbol, company_name, group_type, is_index) VALUES
('VCB', 'Ngân hàng TMCP Ngoại thương Việt Nam', 'Quốc doanh', FALSE),
('BID', 'Ngân hàng TMCP Đầu tư và Phát triển Việt Nam', 'Quốc doanh', FALSE),
('CTG', 'Ngân hàng TMCP Công Thương Việt Nam', 'Quốc doanh', FALSE),
('TCB', 'Ngân hàng TMCP Kỹ thương Việt Nam', 'Tư nhân', FALSE),
('ACB', 'Ngân hàng TMCP Á Châu', 'Tư nhân', FALSE),
('MBB', 'Ngân hàng TMCP Quân đội', 'Tư nhân', FALSE),
('VPB', 'Ngân hàng TMCP Việt Nam Thịnh Vượng', 'Tư nhân', FALSE),
('HDB', 'Ngân hàng TMCP Phát triển TP.HCM', 'Tư nhân', FALSE),
('STB', 'Ngân hàng TMCP Sài Gòn Thương Tín', 'Tư nhân', FALSE),
('VIB', 'Ngân hàng TMCP Quốc tế Việt Nam', 'Tư nhân', FALSE),
('VNINDEX', 'VN-Index', 'Chỉ số', TRUE);

-- fact_price_daily --
INSERT INTO fact_price_daily (company_id, trade_date, open_price, high_price, low_price, close_price, volume)
SELECT 
    dc.company_id,
    s.trade_time::DATE,
    CASE WHEN dc.is_index THEN s.open_price  ELSE s.open_price  * 1000 END,
    CASE WHEN dc.is_index THEN s.high_price  ELSE s.high_price  * 1000 END,
    CASE WHEN dc.is_index THEN s.low_price   ELSE s.low_price   * 1000 END,
    CASE WHEN dc.is_index THEN s.close_price ELSE s.close_price * 1000 END,
    s.volume
FROM staging_price_raw s
JOIN dim_company dc ON dc.symbol = s.symbol
ON CONFLICT (company_id, trade_date) DO NOTHING;

-- fact_financial_quarterly --
INSERT INTO fact_financial_quarterly (company_id, year, quarter, ratio_id, ratio_name, ratio_value)
SELECT DISTINCT ON (dc.company_id, parsed.year, parsed.quarter, parsed.item_id)
    dc.company_id,
    parsed.year,
    parsed.quarter,
    parsed.item_id,
    parsed.item,
    parsed.value
FROM (
    SELECT 
        symbol, item, item_id, value,
        SPLIT_PART(quarter_label, '-Q', 1)::INT AS year,
        SPLIT_PART(SPLIT_PART(quarter_label, '-Q', 2), '_', 1)::INT AS quarter,
        CASE WHEN quarter_label LIKE '%\_1' ESCAPE '\' THEN 1 ELSE 0 END AS is_revised
    FROM staging_financial_raw
) parsed
JOIN dim_company dc ON dc.symbol = parsed.symbol
ORDER BY dc.company_id, parsed.year, parsed.quarter, parsed.item_id, parsed.is_revised DESC
ON CONFLICT (company_id, year, quarter, ratio_id) DO NOTHING;