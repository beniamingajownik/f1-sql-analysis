/*
ANALYSIS: Driver Achievements
PURPOSE:
    - Exploratory insights about drivers achievements throughout their career.  
	
KEY BUSINESS & DATA LOGIC:
	- Answers 'Business Questions' related to Formula 1 Drivers

SOURCE TABLES:
    - gold.v_analytics_driver_standings (WDC)
	- gold.v_analytics_driver_career_summary (Race victories, podiums etc.)
*/

-- 1. World Drivers Champion (WDC) titles per champion
SELECT 
	driver_name,
	COUNT(*) AS wdc_titles
FROM gold.v_analytics_driver_standings
WHERE season_position = 1
GROUP BY driver_id, driver_name
ORDER BY wdc_titles DESC;


-- 2. Main Race victories per driver
SELECT 
	driver_name,
	SUM(race_wins) AS total_race_wins
FROM gold.v_analytics_driver_career_summary
GROUP BY driver_id, driver_name
HAVING SUM(race_wins) > 0
ORDER BY total_race_wins DESC;

-- 3. Main Race podiums per driver
SELECT 
	driver_name,
	SUM(race_podiums) AS total_race_podiums
FROM gold.v_analytics_driver_career_summary
GROUP BY driver_id, driver_name
HAVING SUM(race_podiums) > 0
ORDER BY total_race_podiums DESC;

-- 4. Sprint Race victories per driver
SELECT 
	driver_name,
	SUM(sprint_wins) AS total_sprint_wins
FROM gold.v_analytics_driver_career_summary
GROUP BY driver_id, driver_name
HAVING SUM(sprint_wins) > 0
ORDER BY total_sprint_wins DESC;

-- 5. Sprint Race podiums per driver
SELECT 
	driver_name,
	SUM(sprint_podiums) AS total_spirnt_podiums
FROM gold.v_analytics_driver_career_summary
GROUP BY driver_id, driver_name
HAVING SUM(sprint_podiums) > 0
ORDER BY total_spirnt_podiums DESC;
