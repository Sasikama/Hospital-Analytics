-- Connect to database (MySQL only)
USE hospital_db;

-- OBJECTIVE 1: ENCOUNTERS OVERVIEW

-- a. How many total encounters occurred each year?
SELECT YEAR(start) AS years,
		COUNT(*) AS total_encouters
FROM encounters
GROUP BY YEAR(start)
ORDER BY years;

-- b. For each year, what percentage of all encounters belonged to each encounter class
-- (ambulatory, outpatient, wellness, urgent care, emergency, and inpatient)?

SELECT YEAR(start) AS years,
		ROUND(COUNT(CASE WHEN encounterclass = "ambulatory" THEN encounterclass END) / COUNT(*) * 100, 2) AS ambulatory,
        ROUND(COUNT(CASE WHEN encounterclass = "outpatient" THEN encounterclass END) / COUNT(*) * 100, 2) AS outpatient,
        ROUND(COUNT(CASE WHEN encounterclass = "wellness" THEN encounterclass END) / COUNT(*) * 100, 2) AS wellness,
        ROUND(COUNT(CASE WHEN encounterclass = "urgentcare" THEN encounterclass END) / COUNT(*) * 100, 2) AS urgent_care,
        ROUND(COUNT(CASE WHEN encounterclass = "emergency" THEN encounterclass END) / COUNT(*) * 100, 2) AS emergency,
        ROUND(COUNT(CASE WHEN encounterclass = "inpatient" THEN encounterclass END) / COUNT(*) * 100, 2) AS inpatient,
		COUNT(*) AS total_encouters
FROM encounters
GROUP BY YEAR(start)
ORDER BY years;

-- c. What percentage of encounters were over 24 hours versus under 24 hours?

SELECT 	ROUND(SUM(CASE WHEN TIMESTAMPDIFF(HOUR, START, STOP) >= 24 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS over_24_hours,
		ROUND(SUM(CASE WHEN TIMESTAMPDIFF(HOUR, START, STOP) < 24 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS under_24_hours
FROM encounters;

-- OBJECTIVE 2: COST & COVERAGE INSIGHTS

-- a. How many encounters had zero payer coverage, and what percentage of total encounters does this represent?
SELECT 	* 
FROM 	encounters
WHERE 	PAYER_COVERAGE = 0;

SELECT 
	ROUND(SUM(CASE WHEN PAYER_COVERAGE = 0 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS zero_payer_coverage
FROM encounters;

-- b. What are the top 10 most frequent procedures performed and the average base cost for each?

SELECT 	DESCRIPTION,
		COUNT(CODE) AS total_procedures,
        ROUND(AVG(BASE_COST), 2) AS avg_base_cost
FROM 	procedures
GROUP BY DESCRIPTION
ORDER BY COUNT(CODE) DESC
LIMIT 10;

-- c. What are the top 10 procedures with the highest average base cost and the number of times they were performed?

SELECT 	DESCRIPTION,
        ROUND(AVG(BASE_COST), 2) AS avg_base_cost,
        COUNT(CODE) AS total_procedures
FROM procedures
GROUP BY DESCRIPTION
ORDER BY avg_base_cost DESC
LIMIT 10;

-- d. What is the average total claim cost for encounters, broken down by payer?

SELECT * FROM encounters;
SELECT * FROM payers;

SELECT p.NAME,
		ROUND(AVG(TOTAL_CLAIM_COST), 2) AS avg_total_claim_cost
FROM encounters e
	LEFT JOIN payers p
    ON e.PAYER = p.Id
GROUP BY p.NAME
ORDER BY avg_total_claim_cost DESC;

-- OBJECTIVE 3: PATIENT BEHAVIOR ANALYSIS

-- a. How many unique patients were admitted each quarter over time?

SELECT * FROM patients;
SELECT * FROM encounters;

SELECT YEAR(START) AS yr, QUARTER(START) AS qr, COUNT(DISTINCT PATIENT) AS unique_patient
FROM encounters
GROUP BY YEAR(START) , QUARTER(START) ;

-- b. How many patients were readmitted within 30 days of a previous encounter?

WITH re_adm_date AS (SELECT 
					PATIENT,
					START,
					STOP,
					LEAD(START) OVER(PARTITION BY PATIENT ORDER BY START) AS next_adm_date
				FROM encounters
				ORDER BY PATIENT, START)
SELECT 	COUNT(DISTINCT PATIENT) AS num_patient
FROM 	re_adm_date
WHERE 	DATEDIFF(next_adm_date, STOP) < 30;

-- c. Which patients had the most readmissions?

WITH re_adm_date AS (SELECT 
					PATIENT,
					START,
					STOP,
					LEAD(START) OVER(PARTITION BY PATIENT ORDER BY START) AS next_adm_date
				FROM encounters
				ORDER BY PATIENT, START)
                
SELECT  PATIENT, COUNT(*) AS num_readmission
FROM 	re_adm_date
WHERE 	DATEDIFF(next_adm_date, STOP) < 30
GROUP BY PATIENT
ORDER BY num_readmission DESC;