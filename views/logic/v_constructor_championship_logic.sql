/*
VIEW: v_constructor_championship_logic
PURPOSE:
    - Applies FIA championship rules to the base racing data.
	- Handles "Highest-Finishing Car Only" by picking only the highest result per race.
	- Serves as the final source for standing aggregations.
	
KEY BUSINESS & DATA LOGIC:
	- Implements historical "Dropped Results" logic (1950-1990).  

DATA HIERARCHY & GRAIN:
    - Granularity: One row per constructor per Race

SOURCE TABLES:
    - v_constructor_base
*/

CREATE OR REPLACE VIEW v_constructor_championship_logic AS

WITH results AS (
	SELECT
		*,
		-- Driver rank based on race performance by team (constructor championship points were only given based on the best-placed car per team)
		ROW_NUMBER() OVER(PARTITION BY race_id, constructor_id, session_type ORDER BY finish_position) driver_in_team_rank,

		-- Correcting points scored by the teams in case of a point for fastest lap awarded to the driver
		CASE 
			WHEN year IN (1958, 1959) AND is_fastest_lap = 'true' THEN points - 1.0
			WHEN year IN (1961) THEN (CASE WHEN points = 9 THEN 8 ELSE points END)::numeric
			ELSE points
		END team_points
		
	FROM v_constructor_base
),

season_halves AS (
	SELECT
		*,
	    -- Determining season 'halves' according to F1 rules at the time (added logic to determine season halves of other seasons)
		CASE 
			WHEN year IN (1967, 1968, 1969, 1971, 1972) THEN 
				(CASE WHEN round <= 6 THEN 1 ELSE 2 END)
				
			WHEN year IN (1970) THEN
				(CASE WHEN round <= 7 THEN 1 ELSE 2 END)
				
			WHEN year IN (1973, 1974, 1975, 1976, 1978) THEN
				(CASE WHEN round <= 8 THEN 1 ELSE 2 END)
				
			WHEN year = 1977 THEN
				(CASE WHEN round <= 9 THEN 1 ELSE 2 END)
				
			ELSE (CASE WHEN round <= CEIL(total_races_in_season / 2.0) THEN 1 ELSE 2 END)
		END is_half
	FROM results
),

-- Filtering who had best results between the rest of the drivers
rank_filter AS (
	SELECT 
		* 
	FROM season_halves 
	WHERE (driver_in_team_rank = 1 OR year >= 1979)
),

-- Final calculations in order to determine best results in the season halves and in full duration of the season
in_season_rank AS (
	SELECT 
		*,
    -- Defining a ranking of best results in a season (from best to worst)
		CASE
			WHEN driver_in_team_rank = 1 THEN (
				ROW_NUMBER() OVER(PARTITION BY year, constructor_id, session_type ORDER BY finish_position ASC ,team_points DESC)
			)
			ELSE 0
		END in_season_best_result_rank,

		-- Defining a ranking of best results in every season half (from best to worst)		
		CASE
			WHEN driver_in_team_rank = 1 THEN (
				ROW_NUMBER() OVER(PARTITION BY year, constructor_id, is_half, session_type ORDER BY finish_position ASC, team_points DESC)
			)
			ELSE 0
		END in_half_best_results

	FROM rank_filter
)

SELECT 
	*,
	
	-- Defining the logic of best results which counted to the total season points tally
	CASE 
		-- Counts Highest-Finishing Car Only by picking only the highest result per race
		WHEN driver_in_team_rank > 1 AND year < 1979 THEN 0

		-- Excluding Indy500 races from World Constructor Championship
		WHEN grand_prix_id = 'indianapolis' THEN 0

		-- Excluding Mclaren from 2007 Championship (Disqualified for spying)
		WHEN constructor_id = 'mclaren' AND year = 2007 THEN 0
		
		-- Best n results of the whole season era
		WHEN year IN (1959, 1961, 1962, 1966) 		AND in_season_best_result_rank <= 5  THEN 1
		WHEN year IN (1958, 1960, 1963, 1964, 1965) AND in_season_best_result_rank <= 6  THEN 1

		-- Best n results from each season half (Season split)
		WHEN year IN (1967, 1968, 1969, 1971, 1972) AND is_half = 1 AND in_half_best_results <= 5 THEN 1
		WHEN year IN (1967, 1969, 1971) 			AND is_half = 2 AND in_half_best_results <= 4 THEN 1
		WHEN year IN (1968, 1970, 1972, 1975) 		AND is_half = 2 AND in_half_best_results <= 5 THEN 1	
		WHEN year IN (1973, 1974, 1975, 1976, 1978) AND is_half = 1 AND in_half_best_results <= 7 THEN 1
		WHEN year IN (1973, 1974) 					AND is_half = 2 AND in_half_best_results <= 6 THEN 1
		WHEN year IN (1976, 1977, 1978) 			AND is_half = 2 AND in_half_best_results <= 7 THEN 1
		WHEN year = 1977 							AND is_half = 1 AND in_half_best_results <= 8 THEN 1
		WHEN year = 1970 							AND is_half = 1 AND in_half_best_results <= 6 THEN 1
		
		-- Every result counted to championship (includes Sprint Races)
		WHEN year >= 1979 THEN 1
		ELSE 0
	END counts_to_championship
FROM in_season_rank