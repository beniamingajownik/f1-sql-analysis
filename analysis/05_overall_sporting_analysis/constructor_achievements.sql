/*
ANALYSIS: Constructor Achievements
PURPOSE:
    - Exploratory insights about constructor achievements throughout their participation time in Formula 1.  
	
KEY BUSINESS & DATA LOGIC:
	- Answers 'Business Questions' related to Formula 1 Constructors

DATA HIERARCHY & GRAIN:
    - ?

SOURCE TABLES:
    - gold.v_analytics_constructor_standings (WCC)
	- gold.v_analytics_constructor_career_summary (Race victories, podiums etc.)
*/

-- 1. World Constructors Champion (WCC) titles per team
SELECT 
	constructor_name,
	COUNT(*) AS wcc_titles
FROM gold.v_analytics_constructor_standings
WHERE season_position = 1
GROUP BY constructor_id, constructor_name
ORDER BY wcc_titles DESC;

-- 2. Main Race victories per constructor
SELECT 
	constructor_name,
	SUM(race_wins) AS total_race_wins
FROM gold.v_analytics_constructor_career_summary
GROUP BY constructor_id, constructor_name
HAVING SUM(race_wins) > 0
ORDER BY total_race_wins DESC;

-- 3. Main Race podiums per constructor
SELECT 
	constructor_name,
	SUM(race_podiums) AS total_race_podiums
FROM gold.v_analytics_constructor_career_summary
GROUP BY constructor_id, constructor_name
HAVING SUM(race_podiums) > 0
ORDER BY total_race_podiums DESC;

-- 4. Sprint Race victories per constructor
SELECT 
	constructor_name,
	SUM(sprint_wins) AS total_sprint_wins
FROM gold.v_analytics_constructor_career_summary
GROUP BY constructor_id, constructor_name
HAVING SUM(sprint_wins) > 0
ORDER BY total_sprint_wins DESC;

-- 5. Sprint Race podiums per constructor
SELECT 
	constructor_name,
	SUM(sprint_podiums) AS total_spirnt_podiums
FROM gold.v_analytics_constructor_career_summary
GROUP BY constructor_id, constructor_name
HAVING SUM(sprint_podiums) > 0
ORDER BY total_spirnt_podiums DESC;