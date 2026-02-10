/*
VIEW: v_analytics_constructor_standings
PURPOSE:
    - Provides a final, aggregated summary of constructor performance per season.
    - Serves as the primary source for championship leaderboards and era-based rankings.
	
KEY BUSINESS & DATA LOGIC:
    - Calculates championship points using only records marked as valid by historical FIA rules (counts_to_championship = 1).

DATA HIERARCHY & GRAIN:
    - Granularity: One row per Constructor per Season.

SOURCE TABLES:
    - v_constructor_championship_logic
*/

CREATE OR REPLACE VIEW v_analytics_constructor_standings AS
WITH aggregated_season AS (
	SELECT
		year,
		constructor_name,
		constructor_id,
		-- Aggregating drivers who participated for the constructor in at least one race in a season
		STRING_AGG(DISTINCT driver_name, ' / ') AS season_drivers,
		constructor_nationality,
		constructor_continent,
		engine_manufacturer,
		regulation_era,
		-- Summing only the points that counted towards the championship title
		SUM(CASE WHEN counts_to_championship = 1 THEN team_points ELSE 0 END) total_points		
	FROM v_constructor_championship_logic
	GROUP BY year, constructor_name, constructor_id, constructor_nationality, constructor_continent, engine_manufacturer, regulation_era
)
SELECT
	*,
	-- Ranking constructors within each season based on their points tally
	CASE 
		WHEN year < 1958 THEN 0
		ELSE RANK() OVER(PARTITION BY year ORDER BY total_points DESC)
	END season_position
FROM aggregated_season;