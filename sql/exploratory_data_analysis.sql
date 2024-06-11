-- Exploratory Data Analysis

# date range of dataset
SELECT 
	MIN(`date`), 
    MAX(`date`)
FROM layoffs_staging2
;

# percentage of entries in dataset by country
SELECT 
    country,
    COUNT(*)  AS total_rows,
    COUNT(*) / (SELECT COUNT(*) FROM layoffs_staging2) AS percentage_total_rows
FROM layoffs_staging2
GROUP BY country
ORDER BY percentage_total_rows DESC
;

# max and min total layoffs
SELECT *
FROM layoffs_staging2
WHERE 
	total_laid_off = (SELECT MAX(total_laid_off) FROM layoffs_staging2) OR
	total_laid_off = (SELECT MIN(total_laid_off) FROM layoffs_staging2)
;

# top 5 companies with most layoffs
SELECT 
	company, 
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC LIMIT 5
;

# top 5 industries with most layoffs
SELECT 
	industry, 
    SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC LIMIT 5
;

# total layoffs by year
SELECT 
	YEAR(`date`), 
    SUM(total_laid_off)
FROM layoffs_staging2
WHERE YEAR(`date`) IS NOT NULL
GROUP BY YEAR(`date`)
ORDER BY 1 DESC
;


# rolling sum for total laid off by month
WITH rolling_total AS
(
SELECT 
	SUBSTRING(`date`,1,7) AS `year_month`, 
    SUM(total_laid_off) AS laid_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `year_month`
ORDER BY 1 ASC
)

SELECT 
	`year_month`, 
    laid_off,
	SUM(laid_off) OVER(ORDER BY `year_month`) AS rolling_total
FROM rolling_total
;

# ranking companies per year based on total laid off
WITH company_year (company, years, total_laid_off) AS
(
SELECT 
	company, 
    YEAR(`date`), 
    SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY 
	company, 
    YEAR(`date`)
), 
company_year_rank AS
(
SELECT 
	*, 
    DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
FROM company_year
WHERE years IS NOT NULL
ORDER BY ranking ASC
)

SELECT * 
FROM company_year_rank
WHERE ranking <= 5
ORDER BY years
;

# ranking industries per year based on total laid off
WITH industry_year (industry, years, total_laid_off) AS
(
SELECT 
	industry, 
    YEAR(`date`), 
    SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry, YEAR(`date`)
),
industry_year_rank AS
(
SELECT 
	*, 
    DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
FROM industry_year
WHERE years IS NOT NULL
)

SELECT *
FROM industry_year_rank
WHERE ranking <= 5
;
