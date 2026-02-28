/*
ANALYSIS: Constructor Performance [PER SEASON]
PURPOSE:
    - Exploratory insights about season constructor performance. 
	
KEY BUSINESS & DATA LOGIC:
	- Answers 'Business Questions' related to Formula 1 Constructors on a season level.

SOURCE TABLES:
    - gold.v_analytics_constructor_season_stats 
	- gold.v_analytics_driver_season_stats
*/

-- 1. Percentage of race victories 
SELECT 
	year,
	constructor_name,
	drivers,
	race_wins,
	total_season_races,
	season_race_wins_pct
FROM gold.v_analytics_constructor_season_stats
WHERE race_wins > 0
ORDER BY season_race_wins_pct DESC;


-- 2. Percentage of race podiums  
SELECT 
	year,
	constructor_name,
	drivers,
	race_podiums,
	total_season_races,
	season_race_podiums_pct
FROM gold.v_analytics_constructor_season_stats
WHERE race_podiums > 0 AND constructor_race_entrants > 4
ORDER BY season_race_podiums_pct DESC;


-- 3. Percentage of sprint victories
SELECT 
	year,
	constructor_name,
	drivers,
	sprint_wins,
	total_season_sprints,
	season_sprint_wins_pct
FROM gold.v_analytics_constructor_season_stats
WHERE sprint_wins > 0 AND year > 2020
ORDER BY year ASC, season_sprint_wins_pct DESC;


-- 4. Percentage of sprint podiums  
SELECT 
	year,
	constructor_name,
	drivers,
	sprint_podiums,
	total_season_sprints,
	season_sprint_podiums_pct
FROM gold.v_analytics_constructor_season_stats
WHERE sprint_podiums > 0 AND year > 2020
ORDER BY year ASC, season_sprint_podiums_pct DESC;


-- 5. Percentage of Race 'One-Two' finishes
SELECT 
	year,
	constructor_name,
	drivers,
	race_one_two_finishes,
	total_season_races,
	ROUND(race_one_two_finishes::numeric / NULLIF(total_season_races, 0)::numeric * 100, 2) AS race_one_two_finishes_pct
FROM gold.v_analytics_constructor_season_stats
WHERE race_one_two_finishes > 0 
ORDER BY year ASC, race_one_two_finishes_pct DESC;


-- 6. Percentage of Sprint 'One-Two' finishes
SELECT 
	year,
	constructor_name,
	drivers,
	sprint_one_two_finishes,
	total_season_sprints,
	ROUND(sprint_one_two_finishes::numeric / NULLIF(total_season_sprints, 0)::numeric * 100, 2) AS sprint_one_two_finishes_pct
FROM gold.v_analytics_constructor_season_stats
WHERE sprint_one_two_finishes > 0 AND year > 2020
ORDER BY year ASC, sprint_one_two_finishes_pct DESC;


-- 7. Highest average points 
SELECT 
	year,
	constructor_name,
	avg_race_points
FROM gold.v_analytics_constructor_season_stats
ORDER BY avg_race_points DESC


-- 8. Constructor points trend over time *(year-over-year)*
WITH yearly_summaries AS (
    -- Aggregating to a season level 
    SELECT 
        year,
        driver_id,
        driver_name,
        STRING_AGG(team, ' / ') AS teams,
        SUM(official_season_points) AS total_points_year,
        SUM(season_race_entries) AS total_entries_year
    FROM gold.v_analytics_driver_season_stats
    GROUP BY year, driver_id, driver_name
),

driver_performance AS (
    -- Previous season data 
    SELECT 
        year,
        driver_name,
        teams,
        total_points_year,
        total_entries_year,
		
		-- Previous season points
        LAG(total_points_year) OVER(PARTITION BY driver_id ORDER BY year ASC) AS prev_season_points,
		
		-- Previous year
        LAG(year) OVER(PARTITION BY driver_id ORDER BY year ASC) AS prev_year
    FROM yearly_summaries
)

SELECT 
    year,
    driver_name,
    teams AS team,
    total_entries_year AS current_year_entries,
    total_points_year AS current_points,
    prev_season_points,
	
	-- Point diff shows progress compared to previous year (positive number = progress)
    (total_points_year - prev_season_points) AS points_diff,
	
	-- Growth KPI as a percentage
    ROUND((total_points_year - prev_season_points)::numeric / NULLIF(prev_season_points, 0) * 100, 2) AS yoy_growth_pct
FROM driver_performance
WHERE prev_season_points IS NOT NULL 
    AND year = prev_year + 1 
    AND total_entries_year > 1 
ORDER BY year DESC, points_diff DESC;


-- 9. Driver contribution to team points (% contribution)
WITH constructor_points AS (
    SELECT 
        year,
        driver_name,
        team,
        official_season_points AS driver_points,
		
        -- Aggregating all constructors season points 
        SUM(official_season_points) OVER(PARTITION BY year, team) AS team_total_points
    FROM gold.v_analytics_driver_season_stats
)
SELECT 
    year,
    driver_name,
    team,
    driver_points,
    team_total_points,
    ROUND((driver_points::numeric / NULLIF(team_total_points, 0) * 100), 2) AS contribution_pct
FROM constructor_points
WHERE team_total_points > 0  
ORDER BY year DESC, contribution_pct DESC;


-- 10. Comparison of drivers within the same team
WITH team_stats AS (
	SELECT 
		year,
		team,
		driver_name,
		official_season_points,
		race_wins,
		race_podiums,
		avg_race_finish,
		
		-- Driver with most season points
		MAX(official_season_points) OVER(PARTITION BY year, team) AS team_leader_points,
		
		-- Constructors total season points
		SUM(official_season_points) OVER(PARTITION BY year, team) AS total_team_points,
		
		-- Average constructor finish position
		AVG(avg_race_finish) OVER(PARTITION BY year, team) AS team_avg_finish
	FROM gold.v_analytics_driver_season_stats
)
SELECT 
	year,
	team,
	driver_name,
	official_season_points,
	
	-- Point diff to leader (0 = points leader in a team)
	(official_season_points - team_leader_points) AS points_gap_to_leader,
	
	-- % of points share
	ROUND(official_season_points::numeric / NULLIF(total_team_points, 0) * 100, 2) AS points_share_pct,
	
	-- Effectiveness relative to average constructor finish position
	ROUND(avg_race_finish - team_avg_finish, 2) AS finish_vs_team_avg,
	
	race_wins,
	race_podiums
FROM team_stats
ORDER BY year DESC, team, official_season_points DESC;