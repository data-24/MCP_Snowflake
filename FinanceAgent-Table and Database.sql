USE ROLE ACCOUNTADMIN;

-- New database / schema / warehouse for the second agent
CREATE DATABASE  IF NOT EXISTS SALES_DB;
CREATE SCHEMA    IF NOT EXISTS SALES_DB.ANALYTICS;
CREATE WAREHOUSE IF NOT EXISTS SALES_WH
  WITH WAREHOUSE_SIZE='SMALL' AUTO_SUSPEND=60 AUTO_RESUME=TRUE INITIALLY_SUSPENDED=TRUE;

-- Sample table
CREATE OR REPLACE TABLE SALES_DB.ANALYTICS.ORDERS (
  ORDER_ID          INT,
  CUSTOMER_NAME     STRING,
  REGION            STRING,
  PRODUCT_CATEGORY  STRING,
  ORDER_DATE        DATE,
  QUANTITY          INT,
  AMOUNT            NUMBER(10,2),
  STATUS            STRING
);

INSERT INTO SALES_DB.ANALYTICS.ORDERS VALUES
(1001,'Acme Corp',      'North','Electronics','2025-01-05', 10, 2500.00,'Shipped'),
(1002,'Beta Ltd',       'South','Furniture',  '2025-01-11',  4, 1800.00,'Shipped'),
(1003,'Cyan Inc',       'East', 'Electronics','2025-01-19',  7, 1750.00,'Pending'),
(1004,'Delta LLC',      'West', 'Apparel',    '2025-02-02', 20,  900.00,'Shipped'),
(1005,'Echo GmbH',      'North','Furniture',  '2025-02-14',  2,  950.00,'Cancelled'),
(1006,'Foxtrot Co',     'South','Electronics','2025-02-22', 15, 3750.00,'Shipped'),
(1007,'Golf Partners',  'East', 'Apparel',    '2025-03-03', 30, 1350.00,'Pending'),
(1008,'Hotel Group',    'West', 'Furniture',  '2025-03-10',  5, 2250.00,'Shipped'),
(1009,'India Traders',  'North','Electronics','2025-03-18',  8, 2000.00,'Shipped'),
(1010,'Juliet Retail',  'South','Apparel',    '2025-03-25', 12,  540.00,'Cancelled'),
(1011,'Kilo Systems',   'East', 'Electronics','2025-04-04',  6, 1500.00,'Shipped'),
(1012,'Lima Stores',    'West', 'Furniture',  '2025-04-12',  3, 1350.00,'Pending'),
(1013,'Mike & Sons',    'North','Apparel',    '2025-04-20', 25, 1125.00,'Shipped'),
(1014,'November Ltd',   'South','Electronics','2025-05-01',  9, 2250.00,'Shipped'),
(1015,'Oscar Inc',      'East', 'Furniture',  '2025-05-09',  1,  450.00,'Cancelled'),
(1016,'Papa Corp',      'West', 'Electronics','2025-05-17', 11, 2750.00,'Shipped'),
(1017,'Quebec LLC',     'North','Apparel',    '2025-05-24', 18,  810.00,'Pending'),
(1018,'Romeo GmbH',     'South','Furniture',  '2025-06-02',  6, 2700.00,'Shipped'),
(1019,'Sierra Co',      'East', 'Electronics','2025-06-11', 14, 3500.00,'Shipped'),
(1020,'Tango Group',    'West', 'Apparel',    '2025-06-19', 22,  990.00,'Cancelled');

-- Quick check
SELECT * FROM SALES_DB.ANALYTICS.ORDERS;