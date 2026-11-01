--Drop the table if it already exists 
DROP TABLE IF EXISTS bank_loans;


--Create table
CREATE TABLE bank_loans (
     loan_id VARCHAR(10) PRIMARY KEY,
	 customer_name VARCHAR(50) NOT NULL,
	 age SMALLINT NOT NULL CHECK (age BETWEEN 18 AND 100),
	 gender VARCHAR(15) NOT NULL,
	 annual_income INTEGER NOT NULL CHECK (annual_income > 0),
	 loan_amount INTEGER NOT NULL CHECK (loan_amount > 0),
	 term_months SMALLINT NOT NULL CHECK (term_months IN (36, 60)),
	 interest_rate NUMERIC(5,2) NOT NULL CHECK (interest_rate > 0),
	 credit_score SMALLINT NOT NULL CHECK (credit_score BETWEEN 300 AND 850),
	 loan_purpose VARCHAR(30) NOT NULL,
	 loan_status VARCHAR(30) NOT NULL 
);

SELECT * FROM bank_loans;

--Headline KPIs (matches the workbook's KPI_Summary sheet)
SELECT COUNT(*) AS total_loans,
       SUM(loan_amount) AS total_funding,
       ROUND(AVG(loan_amount), 0) AS avg_loan_amount,
       ROUND(AVG(credit_score), 1) AS avg_credit_score,
       ROUND(AVG(annual_income), 0) AS avg_income,
       ROUND(AVG(interest_rate), 2) AS avg_interest_rate,
       ROUND(SUM(loan_amount * interest_rate) / SUM(loan_amount), 2) AS weighted_avg_rate
FROM bank_loans;


--Loan status mix: count, share, and money
SELECT loan_status,
       COUNT(*) AS loans,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_loans,
       SUM(loan_amount) AS funding,
       ROUND(100.0 * SUM(loan_amount) / SUM(SUM(loan_amount)) OVER (), 1) AS pct_of_funding
FROM bank_loans
GROUP BY loan_status
ORDER BY loans DESC;


--Good vs bad loan KPIs
SELECT CASE WHEN loan_status IN ('Charged Off', 'Late (31-120 days)') THEN 'Bad Loan' ELSE 'Good Loan' END AS loan_quality,
       COUNT(*) AS loans,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_loans,
       SUM(loan_amount) AS funding,
       ROUND(AVG(interest_rate),2) AS avg_rate,
       ROUND(AVG(credit_score),0) AS avg_credit_score
FROM bank_loans
GROUP BY 1
ORDER BY 1 DESC;


--Performance by loan purpose (volume, avg rate, bad-loan rate)
SELECT loan_purpose,
       COUNT(*) AS loans,
       SUM(loan_amount) AS funding,
       ROUND(AVG(loan_amount), 0) AS avg_loan,
       ROUND(AVG(interest_rate), 2) AS avg_rate,
       ROUND(AVG(credit_score), 0) AS avg_score,
       ROUND(100.0 * COUNT(*) FILTER (WHERE loan_status IN ('Charged Off','Late (31-120 days)')) / COUNT(*), 1) AS bad_loan_pct
FROM bank_loans
GROUP BY loan_purpose
ORDER BY bad_loan_pct DESC;


--Term comparison: 36 vs 60 months
SELECT term_months,
       COUNT(*) AS loans,
       SUM(loan_amount) AS funding,
       ROUND(AVG(loan_amount), 0) AS avg_loan,
       ROUND(AVG(interest_rate), 2) AS avg_rate,
       ROUND(100.0 * COUNT(*) FILTER (WHERE loan_status IN ('Charged Off','Late (31-120 days)')) / COUNT(*), 1) AS bad_loan_pct
FROM bank_loans
GROUP BY term_months
ORDER BY term_months;


--Credit score bands: does risk drop as score rises?
SELECT CASE WHEN credit_score < 580 THEN '1. Poor (<580)'
            WHEN credit_score < 670 THEN '2. Fair (580-669)'
            WHEN credit_score < 740 THEN '3. Good (670-739)'
            WHEN credit_score < 800 THEN '4. Very Good (740-799)'
            ELSE '5. Exceptional (800+)' END AS score_band,
       COUNT(*) AS loans,
       SUM(loan_amount) AS funding,
       ROUND(AVG(interest_rate), 2) AS avg_rate,
       ROUND(100.0 * COUNT(*) FILTER (WHERE loan_status IN ('Charged Off','Late (31-120 days)')) / COUNT(*), 1) AS bad_loan_pct
FROM bank_loans
GROUP BY 1
ORDER BY 1;


--Income bands vs loan size and debt burden (loan / income)
SELECT CASE WHEN annual_income < 40000  THEN '1. Under 40k'
            WHEN annual_income < 80000  THEN '2. 40k-80k'
            WHEN annual_income < 120000 THEN '3. 80k-120k'
            ELSE '4. 120k+' END AS income_band,
       COUNT(*) AS loans,
       ROUND(AVG(loan_amount), 0) AS avg_loan,
       ROUND(AVG(loan_amount::numeric / annual_income), 2) AS avg_loan_to_income,
       ROUND(100.0 * COUNT(*) FILTER (WHERE loan_status IN ('Charged Off','Late (31-120 days)')) / COUNT(*), 1) AS bad_loan_pct
FROM bank_loans
GROUP BY 1
ORDER BY 1;


--Age groups
SELECT CASE WHEN age < 30 THEN '18-29'
            WHEN age < 40 THEN '30-39'
            WHEN age < 50 THEN '40-49'
            WHEN age < 60 THEN '50-59'
            ELSE '60+' END AS age_group,
       COUNT(*) AS loans,
       SUM(loan_amount) AS funding,
       ROUND(AVG(annual_income), 0) AS avg_income,
       ROUND(100.0 * COUNT(*) FILTER (WHERE loan_status IN ('Charged Off','Late (31-120 days)')) / COUNT(*), 1) AS bad_loan_pct
FROM bank_loans
GROUP BY 1
ORDER BY 1;


--Gender breakdown
SELECT gender,
       COUNT(*) AS loans,
       SUM(loan_amount) AS funding,
       ROUND(AVG(loan_amount), 0) AS avg_loan,
       ROUND(AVG(credit_score), 0) AS avg_score,
       ROUND(AVG(interest_rate), 2) AS avg_rate
FROM bank_loans
GROUP BY gender
ORDER BY loans DESC;


--Purpose x status matrix (count of loans)
SELECT loan_purpose,
       COUNT(*) FILTER (WHERE loan_status = 'Fully Paid') AS fully_paid,
       COUNT(*) FILTER (WHERE loan_status = 'Current') AS current,
       COUNT(*) FILTER (WHERE loan_status = 'In Grace Period') AS in_grace,
       COUNT(*) FILTER (WHERE loan_status = 'Late (31-120 days)') AS late,
       COUNT(*) FILTER (WHERE loan_status = 'Charged Off') AS charged_off
FROM bank_loans
GROUP BY loan_purpose
ORDER BY loan_purpose;


--Money at risk: charged-off + late balances by purpose (CTE)
WITH risk AS (
    SELECT loan_purpose,
           SUM(loan_amount) FILTER (WHERE loan_status IN ('Charged Off','Late (31-120 days)')) AS at_risk,
           SUM(loan_amount) AS total
    FROM bank_loans
    GROUP BY loan_purpose
)
SELECT loan_purpose, at_risk, total,
       ROUND(100.0 * at_risk / total, 1) AS at_risk_pct,
       ROUND(100.0 * at_risk / SUM(at_risk) OVER (), 1) AS share_of_all_risk
FROM risk
ORDER BY at_risk DESC;

--Risk vs pricing: are riskier segments charged higher rates?
SELECT loan_status,
       ROUND(AVG(interest_rate), 2) AS avg_rate,
       ROUND(AVG(credit_score), 0) AS avg_score,
       ROUND(AVG(annual_income), 0) AS avg_income,
       ROUND(AVG(loan_amount::numeric / annual_income), 2) AS avg_loan_to_income
FROM bank_loans
GROUP BY loan_status
ORDER BY avg_rate DESC;

--Top 10 largest loans with rank (window function)
SELECT RANK() OVER (ORDER BY loan_amount DESC) AS rnk,
       loan_id, customer_name, loan_amount, interest_rate, credit_score, loan_purpose, loan_status
FROM bank_loans
ORDER BY loan_amount DESC
LIMIT 10;

--Highest-risk watchlist: bad loans with low score and high loan-to-income
SELECT loan_id, customer_name, loan_amount, annual_income,
       ROUND(loan_amount::numeric / annual_income, 2) AS loan_to_income,
       credit_score, interest_rate, loan_status
FROM bank_loans
WHERE loan_status IN ('Charged Off','Late (31-120 days)')
  AND credit_score < 640
ORDER BY loan_to_income DESC
LIMIT 15;

--Names with most loans (note: only 17 distinct names exist in this dataset, so names repeat heavily and are not unique customers)
SELECT customer_name,
       COUNT(*) AS loans,
       SUM(loan_amount) AS total_borrowed,
       ROUND(AVG(credit_score), 0) AS avg_score
FROM bank_loans
GROUP BY customer_name
HAVING COUNT(*) > 1
ORDER BY total_borrowed DESC
LIMIT 10;

--Purpose x term: avg rate and bad-loan % in one view
SELECT loan_purpose, term_months,
       COUNT(*) AS loans,
       ROUND(AVG(interest_rate), 2) AS avg_rate,
       ROUND(100.0 * COUNT(*) FILTER (WHERE loan_status IN ('Charged Off','Late (31-120 days)')) / COUNT(*), 1) AS bad_loan_pct
FROM bank_loans
GROUP BY loan_purpose, term_months
ORDER BY loan_purpose, term_months;

--Each loan vs its purpose average (window function)
SELECT loan_id, loan_purpose, loan_amount,
       ROUND(AVG(loan_amount) OVER (PARTITION BY loan_purpose), 0) AS purpose_avg,
       loan_amount - ROUND(AVG(loan_amount) OVER (PARTITION BY loan_purpose), 0) AS diff_from_avg
FROM bank_loans
ORDER BY diff_from_avg DESC
LIMIT 10;
