-- ============================================================
-- BANK REVENUE INTELLIGENCE: Cross-Sell & Lead Prioritization
-- Dataset: 45,211 Bank Customers -- UCI ML Repository "Bank Marketing"
--          (Moro et al., 2014), Portuguese retail bank, 2008-2010
--          Mirrored on Kaggle as "Bank Customer Dataset" (Megasatish)
-- Tools: SQLite / DB Browser for SQLite
-- Author: Ven Anusuri | Financial Advisor -> Data Analyst
-- ============================================================
-- PRODUCTS TRACKED:
--   housing = Housing Loan (Mortgage)
--   loan    = Personal Loan
-- REVENUE ASSUMPTIONS (sourced from real 2026 market data):
--   Mortgage net interest:  ~$5,164/yr/customer = $258,214 avg US mortgage
--                           balance (Experian 2025) x 2% est. net spread
--                           (30-yr rate 6.5%, Freddie Mac PMMS Jul 2026)
--   Personal loan net int.: ~$1,053/yr/customer = $11,699 avg US unsecured
--                           personal loan balance (TransUnion Q4 2025) x 9%
--                           est. net spread (avg APR 12.3%, Bankrate Jul 2026)
--   Combined (no products): ~$3,108/yr/customer = blended avg of above
--   Conversion rates: No-products 10% | Loan X-sell 12% | Mortgage X-sell 8%
--   (within 5-15% range typical for retail cross-sell campaigns per
--   KPI Depot / Bain & Company benchmarks)
--   NOTE: spread percentages (2%, 9%) are analyst estimates -- no public
--   source breaks out NIM by individual retail product. Balances, rates,
--   and conversion benchmarks above are directly sourced; see README.
-- ============================================================


-- ============================================================
-- Q1: CUSTOMER SEGMENTATION BY AGE GROUP
-- Purpose: Life-stage profiling - baseline for NBP logic
-- ============================================================
SELECT
    CASE
        WHEN age BETWEEN 18 AND 25 THEN '18-25 Young Adults'
        WHEN age BETWEEN 26 AND 35 THEN '26-35 Early Career'
        WHEN age BETWEEN 36 AND 45 THEN '36-45 Mid Career'
        WHEN age BETWEEN 46 AND 55 THEN '46-55 Peak Earners'
        WHEN age BETWEEN 56 AND 65 THEN '56-65 Pre Retirement'
        ELSE '65+ Retirement'
    END AS Age_Group,
    COUNT(*)                                                        AS Total_Customers,
    ROUND(AVG(balance), 2)                                          AS Avg_Balance,
    SUM(CASE WHEN housing = 'yes' THEN 1 ELSE 0 END)               AS Has_Mortgage,
    SUM(CASE WHEN loan = 'yes' THEN 1 ELSE 0 END)                  AS Has_Personal_Loan,
    SUM(CASE WHEN defaulter = 'yes' THEN 1 ELSE 0 END)             AS Defaulters
FROM Bank_Customer_Data
GROUP BY Age_Group
ORDER BY MIN(age);


-- ============================================================
-- Q2: BALANCE BY EDUCATION & JOB TYPE
-- Purpose: Identify highest-value segments for wealth products
-- ============================================================
SELECT
    education,
    job,
    COUNT(*)                                                        AS Total_Customers,
    ROUND(AVG(balance), 2)                                          AS Avg_Balance,
    ROUND(MAX(balance), 2)                                          AS Max_Balance,
    ROUND(MIN(balance), 2)                                          AS Min_Balance,
    SUM(CASE WHEN housing = 'yes' THEN 1 ELSE 0 END)               AS Has_Mortgage,
    SUM(CASE WHEN loan = 'yes' THEN 1 ELSE 0 END)                  AS Has_Personal_Loan
FROM Bank_Customer_Data
WHERE balance > 0
GROUP BY education, job
ORDER BY Avg_Balance DESC
LIMIT 20;


-- ============================================================
-- Q3: PRODUCT HOLDING BREAKDOWN BY JOB SEGMENT
-- Purpose: Understand current product mix before sizing the gap
-- ============================================================
SELECT
    job,
    COUNT(*)                                                                        AS Total_Customers,
    SUM(CASE WHEN housing = 'no'  AND loan = 'no'  THEN 1 ELSE 0 END)             AS No_Products,
    SUM(CASE WHEN housing = 'yes' AND loan = 'no'  THEN 1 ELSE 0 END)             AS Mortgage_Only,
    SUM(CASE WHEN housing = 'no'  AND loan = 'yes' THEN 1 ELSE 0 END)             AS Loan_Only,
    SUM(CASE WHEN housing = 'yes' AND loan = 'yes' THEN 1 ELSE 0 END)             AS Both_Products,
    ROUND(AVG(balance), 2)                                                          AS Avg_Balance
FROM Bank_Customer_Data
GROUP BY job
ORDER BY No_Products DESC;


-- ============================================================
-- Q4: HIGH-VALUE CUSTOMER IDENTIFICATION (SEGMENT TIERS)
-- Purpose: Map balance tiers - Premium/High/Mid/Low/Negative
-- ============================================================
SELECT
    CASE
        WHEN balance < 0               THEN 'Negative Balance'
        WHEN balance BETWEEN 0 AND 1000    THEN 'Low Value'
        WHEN balance BETWEEN 1001 AND 5000  THEN 'Mid Value'
        WHEN balance BETWEEN 5001 AND 20000 THEN 'High Value'
        ELSE 'Premium'
    END AS Customer_Segment,
    COUNT(*)                                                        AS Total_Customers,
    ROUND(AVG(balance), 2)                                          AS Avg_Balance,
    SUM(CASE WHEN housing = 'yes' THEN 1 ELSE 0 END)               AS Has_Mortgage,
    SUM(CASE WHEN loan = 'yes' THEN 1 ELSE 0 END)                  AS Has_Loan,
    SUM(CASE WHEN defaulter = 'yes' THEN 1 ELSE 0 END)             AS Defaulters,
    ROUND(AVG(age), 1)                                              AS Avg_Age
FROM Bank_Customer_Data
GROUP BY Customer_Segment
ORDER BY Avg_Balance DESC;


-- ============================================================
-- Q5: PRODUCT PENETRATION RATE (PPR) BY JOB SEGMENT
-- Purpose: Core retail banking KPI - avg products per customer
-- Industry benchmark: top banks target 3-4 products/household
-- For this 2-product dataset, benchmark ceiling = 2.0
-- ============================================================
SELECT
    job,
    COUNT(*)                                                        AS Total_Customers,
    SUM(CASE WHEN housing = 'yes' THEN 1 ELSE 0 END)               AS Customers_With_Mortgage,
    SUM(CASE WHEN loan = 'yes' THEN 1 ELSE 0 END)                  AS Customers_With_Loan,
    SUM(CASE WHEN housing = 'no' AND loan = 'no' THEN 1 ELSE 0 END) AS Customers_No_Products,
    ROUND(
        (SUM(CASE WHEN housing = 'yes' THEN 1 ELSE 0 END) +
         SUM(CASE WHEN loan = 'yes' THEN 1 ELSE 0 END)) * 1.0 / COUNT(*),
    2) AS PPR_Avg_Products_Per_Customer,
    ROUND(
        2.0 - (SUM(CASE WHEN housing = 'yes' THEN 1 ELSE 0 END) +
               SUM(CASE WHEN loan = 'yes' THEN 1 ELSE 0 END)) * 1.0 / COUNT(*),
    2) AS PPR_Gap_To_Ceiling,
    ROUND(
        SUM(CASE WHEN housing = 'no' AND loan = 'no' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
    1) AS Pct_Zero_Products
FROM Bank_Customer_Data
GROUP BY job
ORDER BY Customers_No_Products DESC;


-- ============================================================
-- Q6: REVENUE OPPORTUNITY SIZING BY JOB SEGMENT
-- Purpose: Attach dollar value to every cross-sell gap
-- ============================================================
SELECT
    job,
    COUNT(*)                                                                        AS Total_Customers,
    ROUND(AVG(balance), 2)                                                          AS Avg_Balance,
    SUM(CASE WHEN housing = 'no'  AND loan = 'no'  THEN 1 ELSE 0 END)             AS No_Product_Customers,
    SUM(CASE WHEN housing = 'yes' AND loan = 'no'  THEN 1 ELSE 0 END)             AS Mortgage_Only_Customers,
    SUM(CASE WHEN housing = 'no'  AND loan = 'yes' THEN 1 ELSE 0 END)             AS Loan_Only_Customers,
    ROUND(SUM(CASE WHEN housing = 'no' AND loan = 'no' THEN 1 ELSE 0 END)
          * 0.10 * 3108, 0)                                                         AS Est_Rev_No_Products,
    ROUND(SUM(CASE WHEN housing = 'yes' AND loan = 'no' THEN 1 ELSE 0 END)
          * 0.12 * 1053, 0)                                                         AS Est_Rev_Loan_CrossSell,
    ROUND(SUM(CASE WHEN housing = 'no' AND loan = 'yes' THEN 1 ELSE 0 END)
          * 0.08 * 5164, 0)                                                         AS Est_Rev_Mortgage_CrossSell,
    ROUND(
        (SUM(CASE WHEN housing = 'no' AND loan = 'no' THEN 1 ELSE 0 END) * 0.10 * 3108) +
        (SUM(CASE WHEN housing = 'yes' AND loan = 'no' THEN 1 ELSE 0 END) * 0.12 * 1053) +
        (SUM(CASE WHEN housing = 'no' AND loan = 'yes' THEN 1 ELSE 0 END) * 0.08 * 5164),
    0)                                                                              AS Total_Revenue_Opportunity
FROM Bank_Customer_Data
GROUP BY job
ORDER BY Total_Revenue_Opportunity DESC;


-- ============================================================
-- Q7: NEXT BEST PRODUCT (NBP) ASSIGNMENT BY LIFE STAGE
-- Purpose: Rule-based product recommendation engine
-- Logic: life stage (age) + current products + balance threshold
-- Defaulters excluded from active cross-sell
-- ============================================================
SELECT
    CASE
        WHEN age BETWEEN 18 AND 25 THEN '18-25 Young Adults'
        WHEN age BETWEEN 26 AND 35 THEN '26-35 Early Career'
        WHEN age BETWEEN 36 AND 45 THEN '36-45 Mid Career'
        WHEN age BETWEEN 46 AND 55 THEN '46-55 Peak Earners'
        WHEN age BETWEEN 56 AND 65 THEN '56-65 Pre Retirement'
        ELSE '65+ Retirement'
    END AS Age_Group,
    CASE
        WHEN housing = 'no' AND loan = 'no' AND age <= 30
            THEN 'Personal Loan - Credit Building'
        WHEN housing = 'no' AND loan = 'no' AND age BETWEEN 31 AND 45 AND balance >= 1000
            THEN 'Mortgage - First Home / Upgrade'
        WHEN housing = 'no' AND loan = 'no' AND age BETWEEN 31 AND 45 AND balance < 1000
            THEN 'Personal Loan - Liquidity Bridge'
        WHEN housing = 'no' AND loan = 'no' AND age BETWEEN 46 AND 55
            THEN 'Mortgage - Investment Property'
        WHEN housing = 'no' AND loan = 'no' AND age > 55
            THEN 'Term Deposit / GIC - Capital Preservation'
        WHEN housing = 'yes' AND loan = 'no' AND balance >= 2000
            THEN 'Personal Loan - Creditworthy Mortgage Holder'
        WHEN housing = 'yes' AND loan = 'no' AND balance < 2000
            THEN 'Personal Loan - Home Equity Support'
        WHEN housing = 'no' AND loan = 'yes' AND age BETWEEN 26 AND 55
            THEN 'Mortgage - Loan Holder Ready for Home Product'
        WHEN housing = 'no' AND loan = 'yes' AND age > 55
            THEN 'Term Deposit - Shift to Capital Preservation'
        WHEN housing = 'yes' AND loan = 'yes'
            THEN 'Term Deposit / Investment - Fully Leveraged, Build Savings'
        ELSE 'Financial Review - Advisor Assessment Needed'
    END AS Next_Best_Product,
    COUNT(*)                                                        AS Customer_Count,
    ROUND(AVG(balance), 2)                                          AS Avg_Balance,
    ROUND(AVG(age), 1)                                              AS Avg_Age
FROM Bank_Customer_Data
WHERE defaulter = 'no'
GROUP BY Age_Group, Next_Best_Product
ORDER BY Customer_Count DESC;


-- ============================================================
-- Q8: PRIORITY LEAD SCORING & TIER CLASSIFICATION
-- Purpose: Rank customers for cross-sell outreach priority
-- Score (0-100):
--   Balance tier  -> 0-40 pts  (wealth capacity)
--   Product gap   -> 0-30 pts  (opportunity size)
--   Life stage    -> 0-20 pts  (buying propensity window)
--   No default    -> 0-10 pts  (creditworthiness gate)
-- Tiers: HOT >= 70 | WARM 45-69 | COLD < 45
-- ============================================================
SELECT
    job,
    CASE
        WHEN age BETWEEN 18 AND 25 THEN '18-25 Young Adults'
        WHEN age BETWEEN 26 AND 35 THEN '26-35 Early Career'
        WHEN age BETWEEN 36 AND 45 THEN '36-45 Mid Career'
        WHEN age BETWEEN 46 AND 55 THEN '46-55 Peak Earners'
        WHEN age BETWEEN 56 AND 65 THEN '56-65 Pre Retirement'
        ELSE '65+ Retirement'
    END AS Age_Group,
    SUM(CASE WHEN (
            CASE WHEN balance > 20000               THEN 40
                 WHEN balance BETWEEN 5001 AND 20000 THEN 30
                 WHEN balance BETWEEN 1001 AND 5000  THEN 20
                 WHEN balance BETWEEN 0    AND 1000  THEN 10
                 ELSE 0 END +
            CASE WHEN housing = 'no'  AND loan = 'no'  THEN 30
                 WHEN housing = 'yes' AND loan = 'no'  THEN 15
                 WHEN housing = 'no'  AND loan = 'yes' THEN 15
                 ELSE 5 END +
            CASE WHEN age BETWEEN 26 AND 55 THEN 20
                 WHEN age BETWEEN 56 AND 65 THEN 15
                 WHEN age BETWEEN 18 AND 25 THEN 10
                 ELSE 8 END +
            CASE WHEN defaulter = 'no' THEN 10 ELSE 0 END
        ) >= 70 THEN 1 ELSE 0 END)                                 AS HOT_Leads,
    SUM(CASE WHEN (
            CASE WHEN balance > 20000               THEN 40
                 WHEN balance BETWEEN 5001 AND 20000 THEN 30
                 WHEN balance BETWEEN 1001 AND 5000  THEN 20
                 WHEN balance BETWEEN 0    AND 1000  THEN 10
                 ELSE 0 END +
            CASE WHEN housing = 'no'  AND loan = 'no'  THEN 30
                 WHEN housing = 'yes' AND loan = 'no'  THEN 15
                 WHEN housing = 'no'  AND loan = 'yes' THEN 15
                 ELSE 5 END +
            CASE WHEN age BETWEEN 26 AND 55 THEN 20
                 WHEN age BETWEEN 56 AND 65 THEN 15
                 WHEN age BETWEEN 18 AND 25 THEN 10
                 ELSE 8 END +
            CASE WHEN defaulter = 'no' THEN 10 ELSE 0 END
        ) BETWEEN 45 AND 69 THEN 1 ELSE 0 END)                     AS WARM_Leads,
    SUM(CASE WHEN (
            CASE WHEN balance > 20000               THEN 40
                 WHEN balance BETWEEN 5001 AND 20000 THEN 30
                 WHEN balance BETWEEN 1001 AND 5000  THEN 20
                 WHEN balance BETWEEN 0    AND 1000  THEN 10
                 ELSE 0 END +
            CASE WHEN housing = 'no'  AND loan = 'no'  THEN 30
                 WHEN housing = 'yes' AND loan = 'no'  THEN 15
                 WHEN housing = 'no'  AND loan = 'yes' THEN 15
                 ELSE 5 END +
            CASE WHEN age BETWEEN 26 AND 55 THEN 20
                 WHEN age BETWEEN 56 AND 65 THEN 15
                 WHEN age BETWEEN 18 AND 25 THEN 10
                 ELSE 8 END +
            CASE WHEN defaulter = 'no' THEN 10 ELSE 0 END
        ) < 45 THEN 1 ELSE 0 END)                                   AS COLD_Leads,
    COUNT(*)                                                        AS Total_Customers,
    ROUND(AVG(
        CASE WHEN balance > 20000               THEN 40
             WHEN balance BETWEEN 5001 AND 20000 THEN 30
             WHEN balance BETWEEN 1001 AND 5000  THEN 20
             WHEN balance BETWEEN 0    AND 1000  THEN 10
             ELSE 0 END +
        CASE WHEN housing = 'no'  AND loan = 'no'  THEN 30
             WHEN housing = 'yes' AND loan = 'no'  THEN 15
             WHEN housing = 'no'  AND loan = 'yes' THEN 15
             ELSE 5 END +
        CASE WHEN age BETWEEN 26 AND 55 THEN 20
             WHEN age BETWEEN 56 AND 65 THEN 15
             WHEN age BETWEEN 18 AND 25 THEN 10
             ELSE 8 END +
        CASE WHEN defaulter = 'no' THEN 10 ELSE 0 END
    ), 1)                                                           AS Avg_Lead_Score,
    ROUND(AVG(balance), 2)                                          AS Avg_Balance
FROM Bank_Customer_Data
GROUP BY job, Age_Group
ORDER BY HOT_Leads DESC, Avg_Lead_Score DESC;
