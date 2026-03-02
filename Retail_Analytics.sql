CREATE DATABASE RETAIL_SALES_AND_CUSTOMER_ANALYTICS;

USE RETAIL_SALES_AND_CUSTOMER_ANALYTICS;

-- =====================================================
-- Question:
-- Identify the number of duplicate records in sales_transaction.
-- Create a new table with unique records.
-- Drop the original table and rename the new table.
-- =====================================================

SELECT * FROM SALES_TRANSACTION;

ALTER TABLE SALES_TRANSACTION
RENAME COLUMN ï»¿TransactionID TO TransactionID;

SELECT
	TRANSACTIONID,COUNT(*) FROM SALES_TRANSACTION
GROUP BY TRANSACTIONID
HAVING COUNT(*) > 1;

CREATE TABLE SALES_TRANSACTION_DISTINCT AS
SELECT DISTINCT * FROM SALES_TRANSACTION;

DROP TABLE SALES_TRANSACTION;

ALTER TABLE SALES_TRANSACTION_DISTINCT
RENAME TO SALES_TRANSACTION;

SELECT * FROM SALES_TRANSACTION;

-- =====================================================
-- Question:
-- Identify price discrepancies between sales_transaction
-- and product_inventory tables.
-- Update the discrepancies to match the price.
-- =====================================================

SELECT * FROM PRODUCT_INVENTORY;

ALTER TABLE PRODUCT_INVENTORY
RENAME COLUMN ï»¿ProductID TO ProductID;

SELECT T.TRANSACTIONID,
	T.PRICE TRANSACTIONPRICE,
	I.PRICE INVENTORYPRICE
	FROM SALES_TRANSACTION AS T 
	JOIN PRODUCT_INVENTORY AS I 
	ON T.PRODUCTID=I.PRODUCTID 
	WHERE T.PRICE<>I.PRICE ;

UPDATE SALES_TRANSACTION T 
SET PRICE=(SELECT I.PRICE FROM PRODUCT_INVENTORY AS I  
                    WHERE T.PRODUCTID=I.PRODUCTID )
WHERE T.PRODUCTID IN (SELECT PRODUCTID FROM PRODUCT_INVENTORY AS I 
                                         WHERE
                                        T.PRICE<>I.PRICE);
SELECT * FROM SALES_TRANSACTION;

-- =====================================================
-- Question:
-- Identify NULL values in the dataset and replace them with 'Unknown'
-- =====================================================
SELECT * FROM CUSTOMER_PROFILES;

ALTER TABLE CUSTOMER_PROFILES
RENAME COLUMN ï»¿CustomerID TO CustomerID;

SELECT COUNT(*) FROM CUSTOMER_PROFILES
WHERE CUSTOMERID IS NULL OR
AGE IS NULL OR
GENDER IS NULL OR
LOCATION IS NULL OR JOINDATE IS NULL ;

UPDATE CUSTOMER_PROFILES
SET LOCATION="Unknown"
WHERE LOCATION="";

SELECT * FROM CUSTOMER_PROFILES;

-- =====================================================
-- Question:
-- Clean the DATE column in the dataset
-- (Convert to proper DATE format)
-- =====================================================
SELECT TRANSACTIONID,TRANSACTIONDATE
FROM SALES_TRANSACTION
WHERE STR_TO_DATE(TRANSACTIONDATE, '%Y-%m-%d') IS NULL;

UPDATE SALES_TRANSACTION
SET TRANSACTIONDATE = STR_TO_DATE(TRANSACTIONDATE, '%d/%m/%Y')
WHERE TRANSACTIONDATE IS NOT NULL;

ALTER TABLE SALES_TRANSACTION
MODIFY TRANSACTIONDATE DATE;

-- =====================================================
-- Question:
-- Summarize the total sales and total quantity sold per product
-- =====================================================
SELECT PRODUCTID,
	SUM(QUANTITYPURCHASED) AS TOTALUNITSSOLD,
    SUM(PRICE*QUANTITYPURCHASED) AS TOTALSALES
    FROM SALES_TRANSACTION
    GROUP BY PRODUCTID
    ORDER BY TOTALSALES DESC;
    
-- =====================================================
-- Question:
-- Count the number of transactions per customer
-- to understand purchase frequency
-- =====================================================
SELECT CUSTOMERID,
		COUNT(*) AS NUMBEROFTRANSACTIONS
		FROM SALES_TRANSACTION
		GROUP BY CUSTOMERID
		ORDER BY
		NUMBEROFTRANSACTIONS DESC;
        
-- =====================================================
-- Question:
-- Evaluate product category performance based on total sales
-- =====================================================
SELECT I.CATEGORY,
		SUM(S.QUANTITYPURCHASED) AS TOTALUNITSSOLD,
		SUM(I.PRICE*S.QUANTITYPURCHASED) AS TOTALSALES
		FROM SALES_TRANSACTION AS S 
		JOIN PRODUCT_INVENTORY AS I 
		ON S.PRODUCTID=I.PRODUCTID
	    GROUP BY I.CATEGORY
		ORDER BY TOTALSALES DESC;
        
-- =====================================================
-- Question:
-- Find top 10 products with highest total sales revenue
-- =====================================================
SELECT PRODUCTID,
	SUM(QUANTITYPURCHASED*PRICE) AS TOTALREVENUE
	FROM SALES_TRANSACTION
	GROUP BY PRODUCTID
	ORDER BY TOTALREVENUE DESC
	LIMIT 10;
    
-- =====================================================
-- Question:
-- Find the bottom 10 products with least units sold
-- (only products where at least one unit was sold)
-- =====================================================
SELECT PRODUCTID,
		SUM(QUANTITYPURCHASED) AS TOTALUNITSSOLD
		FROM SALES_TRANSACTION
		GROUP BY PRODUCTID
		HAVING TOTALUNITSSOLD > 0
		ORDER BY TOTALUNITSSOLD ASC 
		LIMIT 10;
        
-- =====================================================
-- Question:
-- Identify sales trend to understand revenue pattern
-- =====================================================
SELECT 
 CAST(TRANSACTIONDATE AS  DATE) AS DATETRANS,
 COUNT(*) AS TRANSACTION_COUNT,
 SUM(QUANTITYPURCHASED) AS TOTALUNITSSOLD,
 SUM(PRICE*QUANTITYPURCHASED) AS TOTALSALES
 FROM SALES_TRANSACTION
 GROUP BY DATETRANS
 ORDER BY DATETRANS DESC;
 
 -- =====================================================
-- Question:
-- Calculate Month-on-Month (MoM) growth rate of sales
-- =====================================================
WITH MONTHLY_SALES AS (
    SELECT 
        DATE_FORMAT(TRANSACTIONDATE, '%Y-%m') AS SALES_MONTH,
        SUM(QUANTITYPURCHASED * PRICE) AS TOTAL_REVENUE
    FROM SALES_TRANSACTION
    GROUP BY DATE_FORMAT(TRANSACTIONDATE, '%Y-%m')
)

SELECT 
    SALES_MONTH,
    TOTAL_REVENUE,
    LAG(TOTAL_REVENUE) OVER (ORDER BY SALES_MONTH) AS PREVIOUS_MONTH_REVENUE,
    ROUND(
        (TOTAL_REVENUE - LAG(TOTAL_REVENUE) OVER (ORDER BY SALES_MONTH))
        / LAG(TOTAL_REVENUE) OVER (ORDER BY SALES_MONTH) * 100,
        2
    ) AS MOM_GROWTH_PERCENT
FROM MONTHLY_SALES
ORDER BY SALES_MONTH;

-- =====================================================
-- Question:
-- Find customers with high number of transactions
-- and high total spent
-- =====================================================
SELECT CUSTOMERID,
		COUNT(*) AS NUMBEROFTRANSACTIONS,
		SUM(PRICE*QUANTITYPURCHASED) AS TOTALSPENT
		FROM SALES_TRANSACTION
		GROUP BY CUSTOMERID 
		HAVING NUMBEROFTRANSACTIONS > 10 AND
		TOTALSPENT > 1000
		ORDER BY TOTALSPENT DESC;
        
-- =====================================================
-- Question:
-- Find customers with low number of transactions
-- and low total spent (occasional customers)
-- =====================================================
SELECT CUSTOMERID,
		COUNT(*) AS NUMBEROFTRANSACTIONS,
		SUM(PRICE*QUANTITYPURCHASED) AS TOTALSPENT
		FROM SALES_TRANSACTION
		GROUP BY CUSTOMERID
		HAVING NUMBEROFTRANSACTIONS<=2 
        ORDER BY NUMBEROFTRANSACTIONS ASC,TOTALSPENT DESC;
        
-- =====================================================
-- Question:
-- Find total number of purchases made by each customer
-- against each product to identify repeat customers
-- =====================================================
SELECT CUSTOMERID,
	PRODUCTID,
	COUNT(*) AS TIMESPURCHASED
	FROM SALES_TRANSACTION
	GROUP BY 
	CUSTOMERID,
	PRODUCTID
	HAVING TIMESPURCHASED>1
	ORDER BY TIMESPURCHASED DESC;
    
-- =====================================================
-- Question:
-- Find the duration between first and last purchase
-- for each customer to measure customer loyalty
-- =====================================================
SELECT CUSTOMERID,
MIN(DATE_UPDT) AS FIRSTPURCHASE,
MAX(DATE_UPDT) AS LASTPURCHASE,
DATEDIFF(MAX(DATE_UPDT),MIN(DATE_UPDT)) AS DAYSBETWEENPURCHASES

    FROM(SELECT CUSTOMERID,STR_TO_DATE(TRANSACTIONDATE,'%Y-%m-%d') AS DATE_UPDT FROM SALES_TRANSACTION
    ) A 
	GROUP BY CUSTOMERID 
    HAVING DATEDIFF(MAX(DATE_UPDT),MIN(DATE_UPDT))>0 
    ORDER BY DAYSBETWEENPURCHASES DESC;
    
-- =====================================================
-- Question:
-- Segment customers based on total quantity purchased
-- and count customers in each segment
-- =====================================================
WITH CTE AS (
    SELECT
        C.CUSTOMERID,
        SUM(S.QUANTITYPURCHASED) AS TOTAL_QUANTITY
    FROM SALES_TRANSACTION AS S
    JOIN CUSTOMER_PROFILES AS C
        ON S.CUSTOMERID = C.CUSTOMERID
    GROUP BY C.CUSTOMERID
),
CTE2 AS (
    SELECT
        CUSTOMERID,
        TOTAL_QUANTITY,
        CASE
            WHEN TOTAL_QUANTITY BETWEEN 1 AND 10 THEN "LOW"
            WHEN TOTAL_QUANTITY BETWEEN 11 AND 30 THEN "MED"
            ELSE "HIGH"
        END AS CUSTOMERSEGMENT
    FROM CTE
)
SELECT
    CUSTOMERSEGMENT,
    COUNT(*) AS NUMBER_OF_CUSTOMERS
FROM CTE2
GROUP BY CUSTOMERSEGMENT;









