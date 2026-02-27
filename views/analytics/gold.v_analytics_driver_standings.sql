/*
VIEW: v_analytics_driver_standings
PURPOSE:
    - Provides a final, aggregated summary of driver performance per season.
    - Serves as the primary source for championship leaderboards and era-based rankings.
	
KEY BUSINESS & DATA LOGIC:
    - Calculates championship points using only records marked as valid by historical FIA rules (counts_to_championship = 1).
    - Handles in-season team switches by concatenating all constructors for which the driver competed during that year.

DATA HIERARCHY & GRAIN:
    - Granularity: One row per Driver per Season.

SOURCE TABLES:
    - v_driver_championship_logic
*/

CREATE OR REPLACE VIEW v_analytics_driver_standings AS
WITH aggregated_season AS (
	SELECT
		year,
		driver_name,
		driver_id,
		-- Aggregating teams in case of in-season team switch
		STRING_AGG(DISTINCT team, ' / ') AS team,
		driver_nationality,
		driver_continent,
		regulation_era,
		-- Summing only the points that counted towards the championship title
		SUM(CASE WHEN counts_to_championship = 1 THEN points ELSE 0 END) total_points		
	FROM v_driver_championship_logic
	GROUP BY year, driver_name, driver_id, driver_nationality, driver_continent, regulation_era
)
SELECT
	*,
	-- Ranking drivers within each season based on their points tally
	RANK() OVER(PARTITION BY year ORDER BY total_points DESC) season_position
FROM aggregated_season