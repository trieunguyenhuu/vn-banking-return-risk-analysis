CREATE TABLE dim_company (
    company_id   SERIAL PRIMARY KEY,
    symbol       VARCHAR(10) UNIQUE NOT NULL,   -- VCB, BID, ..., VNINDEX
    company_name VARCHAR(255),
    group_type   VARCHAR(20),                    -- 'Quoc doanh', 'Tu nhan'
    is_index     BOOLEAN DEFAULT FALSE            -- TRUE cho dòng VNINDEX
);

CREATE TABLE fact_price_daily (
    price_id    SERIAL PRIMARY KEY,
    company_id  INT NOT NULL REFERENCES dim_company(company_id),
    trade_date  DATE NOT NULL,
    open_price  NUMERIC(12,2),
    high_price  NUMERIC(12,2),
    low_price   NUMERIC(12,2),
    close_price NUMERIC(12,2),
    volume      BIGINT,
    UNIQUE(company_id, trade_date)
);

CREATE TABLE fact_financial_quarterly (
    fin_id      SERIAL PRIMARY KEY,
    company_id  INT NOT NULL REFERENCES dim_company(company_id),
    year        INT NOT NULL,
    quarter     INT NOT NULL,
    ratio_id    VARCHAR(100) NOT NULL,   -- item_id: pe_ratio, roe, nim, beta...
    ratio_name  VARCHAR(255),            -- item: tên tiếng Việt đầy đủ
    ratio_value NUMERIC(20,4),
    UNIQUE(company_id, year, quarter, ratio_id)
);

CREATE TABLE staging_price_raw (
    symbol      VARCHAR(10),
    trade_time  TIMESTAMP,
    open_price  NUMERIC,
    high_price  NUMERIC,
    low_price   NUMERIC,
    close_price NUMERIC,
    volume      BIGINT
);

CREATE TABLE staging_financial_raw (
    symbol      VARCHAR(10),
    item        VARCHAR(255),
    item_id     VARCHAR(100),
    quarter_label VARCHAR(20),
    value       NUMERIC
);