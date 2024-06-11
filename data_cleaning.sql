-- Removing duplicates

# create staging table
CREATE TABLE layoffs_staging
LIKE layoffs
;

INSERT INTO layoffs_staging
SELECT * 
FROM layoffs;

# create cte that has extra row_num column using partition on all columns
WITH duplicate_cte AS
(
SELECT 
	*,
	ROW_NUMBER() OVER(
		PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
		) as row_num
FROM layoffs_staging
)
# view duplicate rows
SELECT *
FROM duplicate_cte
WHERE row_num > 1
;

# create second staging table with added row_num column
DROP TABLE IF EXISTS layoffs_staging2;
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT 
	*,
	ROW_NUMBER() OVER(
		PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
		) as row_num
FROM layoffs_staging
;

# remove duplicates
DELETE 
FROM layoffs_staging2
WHERE row_num > 1
;

-- Standardisation

# company column
# removing leading/trailing white spaces
UPDATE layoffs_staging2
SET company = TRIM(company)
;

# industry column
# combine similar crypto industry unique values 
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%'
;

# location columns
# combine dusseldorf values
UPDATE layoffs_staging2
SET location = 'Dusseldorf'
WHERE location LIKE '%sseldorf'
;

# fix florianopolis spelling
UPDATE layoffs_staging2
SET location = 'Florianopolis'
WHERE location LIKE 'Florian%'
;

# combine malmo values
UPDATE layoffs_staging2
SET location = 'Malmo'
WHERE location LIKE 'Malm%'
;

# country column
# remove punctuation from values
UPDATE layoffs_staging2
SET country =  TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%'
;

# date column
# change to date format 
UPDATE layoffs_staging2
SET `date` = str_to_date(`date`, '%m/%d/%Y')
;

# change date column to date type
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE
;

-- Null values
# industry column
# set '' to null
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = ''
;

# fill missing value with existing industry value
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL
;

-- removing rows/columns
# remove rows where no values in total_laid_off and percentage_laid_off columns
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL and percentage_laid_off IS NULL
;

# drop row_num column
ALTER TABLE layoffs_staging2
DROP COLUMN row_num
;

-- For investigation
# view table
SELECT * 
FROM layoffs_staging2
;




