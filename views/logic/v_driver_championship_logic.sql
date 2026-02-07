/*
VIEW: v_driver_championship_logic
PURPOSE:
    - Applies FIA championship rules to the base racing data.
	- Handles "Shared Drives" by picking only the best result for a driver per race.
	- Serves as the final source for standing aggregations.
	
KEY BUSINESS & DATA LOGIC:
	- Implements historical "Dropped Results" logic (1950-1990).  

DATA HIERARCHY & GRAIN:
    - Granularity: One row per Driver per Race (in case of "Shared Drives" - results consists only of best finish_position)

SOURCE TABLES:
    - v_driver_base
*/

CREATE OR REPLACE VIEW v_driver_championship_logic AS

-- Handling "Shared Drives" (drivers with multiple records in the same race)
WITH unified_results AS (
	SELECT DISTINCT ON (year, race_id, driver_id, session_type)
	    *
	FROM v_driver_base
	ORDER BY year, race_id, driver_id, session_type, finish_position ASC, points DESC
),

-- Calculating season halves
season_halves AS (
	SELECT
		*,
	    -- Determining season 'halves' according to F1 rules at the time (added logic to determine season halves of other seasons)
		CASE 
			WHEN year IN (1967, 1968, 1969, 1971, 1972) THEN 
				(CASE WHEN round <= 6 THEN 1 ELSE 2 END)
				
			WHEN year IN (1970, 1979, 1980) THEN
				(CASE WHEN round <= 7 THEN 1 ELSE 2 END)
				
			WHEN year IN (1973, 1974, 1975, 1976, 1978) THEN
				(CASE WHEN round <= 8 THEN 1 ELSE 2 END)
				
			WHEN year = 1977 THEN
				(CASE WHEN round <= 9 THEN 1 ELSE 2 END)
				
			ELSE (CASE WHEN round <= CEIL(total_races_in_season / 2.0) THEN 1 ELSE 2 END)
		END is_half
	FROM unified_results
),

-- Final calculations in order to determine best results in the season halves and in full duration of the season
in_season_rank AS (
	SELECT 
		*,
        -- Defining a ranking of best results in a season by driver (from best to worst)
		ROW_NUMBER() OVER(PARTITION BY year, driver_id, session_type ORDER BY finish_position ASC, points DESC) AS in_season_best_result_rank,

        -- Defining a ranking of best results in every season half by driver (from best to worst)
		ROW_NUMBER() OVER(PARTITION BY year, driver_id, is_half, session_type ORDER BY finish_position ASC, points DESC) AS in_half_best_results
	FROM season_halves
)

SELECT 
	*,

	-- Defining the logic of best results which counted to the total season points tally
	CASE 
		-- Best n results of the whole season era
		WHEN year BETWEEN 1950 AND 1953									AND in_season_best_result_rank <= 4  THEN 1
		WHEN year IN (1954, 1955, 1956, 1957, 1959, 1961, 1962, 1966) 	AND in_season_best_result_rank <= 5  THEN 1
		WHEN year IN (1958, 1960, 1963, 1964, 1965) 					AND in_season_best_result_rank <= 6  THEN 1
		WHEN year BETWEEN 1981 AND 1990 								AND in_season_best_result_rank <= 11 THEN 1

		-- Best n results from each season half (Season split)
		WHEN year IN (1967, 1968, 1969, 1971, 1972, 1980) 	AND is_half = 1 AND in_half_best_results <= 5 THEN 1
		WHEN year IN (1967, 1969, 1971, 1979) 				AND is_half = 2 AND in_half_best_results <= 4 THEN 1
		WHEN year IN (1968, 1970, 1972, 1975, 1980) 		AND is_half = 2 AND in_half_best_results <= 5 THEN 1	
		WHEN year IN (1973, 1974, 1975, 1976, 1978) 		AND is_half = 1 AND in_half_best_results <= 7 THEN 1
		WHEN year IN (1973, 1974) 							AND is_half = 2 AND in_half_best_results <= 6 THEN 1
		WHEN year IN (1976, 1977, 1978) 					AND is_half = 2 AND in_half_best_results <= 7 THEN 1
		WHEN year = 1977 									AND is_half = 1 AND in_half_best_results <= 8 THEN 1
		WHEN year = 1979 									AND is_half = 1 AND in_half_best_results <= 4 THEN 1
		WHEN year = 1970 									AND is_half = 1 AND in_half_best_results <= 6 THEN 1
		
		-- Every result counted to championship (includes Sprint Races)
		WHEN year >= 1991 THEN 1
		ELSE 0
	END counts_to_championship

FROM in_season_rank