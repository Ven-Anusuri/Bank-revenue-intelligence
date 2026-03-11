# 👥 Customer Financial Profile Analysis

![Tableau](https://img.shields.io/badge/Tableau-E97627?style=for-the-badge&logo=tableau&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-4479A1?style=for-the-badge&logo=sqlite&logoColor=white)

## 📊 Live Dashboard
🔗 [View on Tableau Public](https://public.tableau.com/app/profile/ven.anusuri/viz/CustomerFinancialProfileAnalysisDashboard/CustomerFinancialProfileAnalysisDashboard?publish=yes)

---

## 📌 Project Overview

This project analyzes the financial profiles of 45,000+ bank customers to uncover segmentation insights, cross-sell opportunities, and high-value customer characteristics.

As a former TD Bank financial advisor, I designed this analysis to mirror real-world customer profiling work done by bank data teams — identifying which customers to target, which carry risk, and where product penetration gaps exist.

---

## 🎯 Business Questions Answered

- Which age group holds the highest average account balance?
- Which job segments represent the greatest cross-sell opportunities?
- How are customers distributed across value tiers (Premium, High, Mid, Low)?
- What is the relationship between education, employment, and account balance?
- Where is default risk concentrated across customer segments?

---

## 📈 Dashboard Features

| Chart | Description |
|-------|-------------|
| **Customer Count by Age Group** | Bar chart showing customer distribution across 6 age segments |
| **Average Balance by Age Group** | Comparison of wealth accumulation across life stages |
| **Cross-Sell Opportunities by Job** | Identifies job segments with highest number of customers holding no products |
| **Customer Segment Distribution** | Bubble chart showing Premium, High, Mid, Low and Negative balance segments |

---

## 🛠️ Tools & Technologies

- **SQL (SQLite / DB Browser)** — Data cleaning, aggregation, and segmentation queries
- **Tableau Public** — Dashboard design and visualization
- **Kaggle** — Source dataset (Bank Customer Dataset)

---

## 📂 Data Source

- **Dataset:** [Bank Customer Dataset](https://www.kaggle.com/datasets/megasatish/bank-customer-dataset) — Kaggle (Megasatish)
- **Records:** 45,211 customers
- **Features:** Age, Job, Education, Balance, Housing Loan, Personal Loan, Defaulter status

---

## 🧹 SQL Queries

### Query 1 — Customer Segmentation by Age Group
```sql
SELECT 
    CASE 
        WHEN age BETWEEN 18 AND 25 THEN '18-25 Young Adults'
        WHEN age BETWEEN 26 AND 35 THEN '26-35 Early Career'
        WHEN age BETWEEN 36 AND 45 THEN '36-45 Mid Career'
        WHEN age BETWEEN 46 AND 55 THEN '46-55 Peak Earners'
        WHEN age BETWEEN 56 AND 65 THEN '56-65 Pre Retirement'
        ELSE '65+ Retirement'
    END AS Age_Group,
    COUNT(*) AS Total_Customers,
    ROUND(AVG(balance), 2) AS Avg_Balance,
    SUM(CASE WHEN housing = 'yes' THEN 1 ELSE 0 END) AS Has_Mortgage,
    SUM(CASE WHEN loan = 'yes' THEN 1 ELSE 0 END) AS Has_Personal_Loan,
    SUM(CASE WHEN defaulter = 'yes' THEN 1 ELSE 0 END) AS Defaulters
FROM Bank_Customer_Data
GROUP BY Age_Group
ORDER BY MIN(age);
```

### Query 2 — Balance by Education & Job Type
```sql
SELECT 
    education,
    job,
    COUNT(*) AS Total_Customers,
    ROUND(AVG(balance), 2) AS Avg_Balance,
    ROUND(MAX(balance), 2) AS Max_Balance,
    ROUND(MIN(balance), 2) AS Min_Balance,
    SUM(CASE WHEN housing = 'yes' THEN 1 ELSE 0 END) AS Has_Mortgage,
    SUM(CASE WHEN loan = 'yes' THEN 1 ELSE 0 END) AS Has_Personal_Loan
FROM Bank_Customer_Data
WHERE balance > 0
GROUP BY education, job
ORDER BY Avg_Balance DESC
LIMIT 20;
```

### Query 3 — Cross-Sell Opportunity Analysis
```sql
SELECT 
    job,
    COUNT(*) AS Total_Customers,
    SUM(CASE WHEN housing = 'no' AND loan = 'no' THEN 1 ELSE 0 END) AS No_Products,
    SUM(CASE WHEN housing = 'yes' AND loan = 'no' THEN 1 ELSE 0 END) AS Mortgage_Only,
    SUM(CASE WHEN housing = 'no' AND loan = 'yes' THEN 1 ELSE 0 END) AS Loan_Only,
    SUM(CASE WHEN housing = 'yes' AND loan = 'yes' THEN 1 ELSE 0 END) AS Both_Products,
    ROUND(AVG(balance), 2) AS Avg_Balance
FROM Bank_Customer_Data
GROUP BY job
ORDER BY No_Products DESC;
```

### Query 4 — High Value Customer Identification
```sql
SELECT 
    CASE 
        WHEN balance < 0 THEN 'Negative Balance'
        WHEN balance BETWEEN 0 AND 1000 THEN 'Low Value'
        WHEN balance BETWEEN 1001 AND 5000 THEN 'Mid Value'
        WHEN balance BETWEEN 5001 AND 20000 THEN 'High Value'
        ELSE 'Premium'
    END AS Customer_Segment,
    COUNT(*) AS Total_Customers,
    ROUND(AVG(balance), 2) AS Avg_Balance,
    SUM(CASE WHEN housing = 'yes' THEN 1 ELSE 0 END) AS Has_Mortgage,
    SUM(CASE WHEN loan = 'yes' THEN 1 ELSE 0 END) AS Has_Loan,
    SUM(CASE WHEN defaulter = 'yes' THEN 1 ELSE 0 END) AS Defaulters,
    ROUND(AVG(age), 1) AS Avg_Age
FROM Bank_Customer_Data
GROUP BY Customer_Segment
ORDER BY Avg_Balance DESC;
```

---

## 💡 Key Insights

- **65+ customers hold the highest average balance ($2,791)** despite being the smallest segment — prime targets for GICs and estate planning products
- **Management segment has 4,206 customers with no products** and an average balance of $1,766 — the single largest cross-sell opportunity
- **Premium customers (balance >$20K) have zero defaulters** — lowest risk, highest value segment deserving priority service
- **3,743 customers carry negative balances** with 438 defaulters — immediate collections and credit risk management priority
- **Tertiary educated retirees** show the strongest balance-to-loan ratio — ideal wealth management targets

---

## 🗂️ Repository Structure

```
📁 customer-financial-profile-analysis/
├── 📄 README.md
├── 📁 data/
│   ├── q1_age_segmentation.csv
│   ├── q2_education_job_balances.csv
│   ├── q3_crosssell_opportunities.csv
│   └── q4_customer_segments.csv
├── 📁 sql/
│   └── customer_profile_queries.sql
├── 📁 screenshots/
│   └── dashboard_overview.png
```

---

## 🔮 Future Enhancements

- Add **geographic analysis** by region to identify location-based trends
- Include **time-series analysis** to track customer balance changes over time
- Build **predictive model** to score cross-sell likelihood per customer
- Add **product penetration rate** by segment for executive reporting

---

## 👤 About Me

**Ven Anusuri** | Financial Advisor → Data Analyst

- 3+ years experience as a Financial Advisor at **TD Bank**
- Certifications: CSC, PFSA, FP-1, BCO, Google Data Analytics, Bloomberg Market Concepts
- Building a 10-project data analytics portfolio bridging finance domain expertise with data skills

🔗 [Tableau Public Profile](https://public.tableau.com/app/profile/ven.anusuri)
🔗 [Project 1 — Canadian Big 5 Banks Stock Dashboard](https://public.tableau.com/app/profile/ven.anusuri/viz/CanadianBig5Banks-StockPerformanceDashboard/Dashboard1)

---
*Project 2 of 10 — Financial Data Analytics Portfolio*
