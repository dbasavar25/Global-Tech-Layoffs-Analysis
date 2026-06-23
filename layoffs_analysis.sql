-- Top Industry layoff Each year

WITH industry_layoff_year AS
(
SELECT industry,YEAR(`date`) AS year,SUM(total_laid_off) AS laid_off
FROM layoffs_staging2
WHERE industry IS NOT NULL
 AND `date` IS NOT NULL
GROUP BY industry,year
)
SELECT industry, year,laid_off,DENSE_RANK() OVER(PARTITION BY year ORDER BY laid_off DESC) AS Rank_industry
FROM industry_layoff_year;

-- Month-over-month

WITH MONTH_over_Month AS
(
SELECT
DATE_FORMAT(`date`,'%Y-%m') AS month,
SUM(total_laid_off) AS laid_off
FROM layoffs_staging2
WHERE `date` IS NOT NULL
GROUP BY month
),mom AS
(
SELECT month,laid_off, LAG(laid_off) OVER(ORDER BY month) AS previous_month
FROM MONTH_over_Month
)
SELECT *,
ROUND((laid_off-previous_month)*100.0/previous_month,2) AS mom_growth_pct
FROM mom;

-- RECOVERY ANALYSIS

WITH recovery AS
(
    SELECT
        industry,
        SUM(CASE WHEN YEAR(`date`) = 2020 THEN total_laid_off ELSE 0 END) AS layoffs_2020,
        SUM(CASE WHEN YEAR(`date`) = 2023 THEN total_laid_off ELSE 0 END) AS layoffs_2023
    FROM layoffs_staging2
    GROUP BY industry
)

SELECT *,
       ROUND(
           (layoffs_2020 - layoffs_2023) * 100.0
           / NULLIF(layoffs_2020,0),
           2
       ) AS recovery_pct
FROM recovery
ORDER BY recovery_pct DESC;

-- TOP 5 COMPANIES PER INDUSTRY TO LAYOFF

WITH company_industry AS
(
    SELECT
        industry,
        company,
        SUM(total_laid_off) AS total_layoffs
    FROM layoffs_staging2
    WHERE industry IS NOT NULL
    GROUP BY industry, company
),

company_rank AS
(
    SELECT *,
           DENSE_RANK() OVER(
               PARTITION BY industry
               ORDER BY total_layoffs DESC
           ) AS company_rank
    FROM company_industry
)

SELECT *
FROM company_rank
WHERE company_rank <= 5
ORDER BY industry, company_rank;


SELECT *
FROM layoffs_staging2;