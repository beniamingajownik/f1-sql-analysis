/*
VIEW: gold.v_report_constructor_master
PURPOSE:
    - Provides a centralized, Power BI-ready table for constructor seasonal performance analysis.
    - Serves as the primary source for "Team Performance", "Engineering Stability", and "R&D Progress" dashboard sections.
	
KEY BUSINESS & DATA LOGIC:
    - Consolidates seasonal standings (WCC) with advanced race metrics like Overtaking Efficiency (team_avg_pos_gain).
    - Features a Chassis Stability Index based on qualifying volatility to measure car setup versatility across different circuits.
    - Includes a Mid-Season Development Index to track technical progress and R&D effectiveness relative to the seasonal mean.
    - Integrates technical reliability metrics (DNF rates) for operational benchmarking.

DATA HIERARCHY & GRAIN:
    - Granularity: One row per constructor per season (Year)

SOURCE TABLES:
    - gold.v_analytics_constructor_season_stats
    - gold.v_analytics_constructor_standings
    - gold.v_analytics_race_evolution
*/

CREATE OR REPLACE VIEW gold.v_report_constructor_master AS

SELECT 
    -- 1. Identity & Context
    cs.year,
    cs.constructor_id,
    cs.constructor_name,
    cs.regulation_era,

    -- 2. Performance
    cst.season_position AS wcc_position,
    CASE WHEN cst.season_position = 1 THEN 1 ELSE 0 END AS is_wcc_champion,
    cs.official_season_points,
    cs.constructor_race_entries AS total_season_entries, 
    cs.race_wins,
    cs.race_podiums,

    -- 3. Race Dynamics
    ROUND(AVG(re.grid_position - re.finish_position), 3) AS team_avg_pos_gain,
    ROUND(AVG(re.constructor_cum_stddev_grid), 3) AS chassis_stability_index,
    ROUND(AVG(re.constructor_finish_season_delta), 3) AS mid_season_dev_index,

    -- 4. Reliability & Efficiency
    cs.race_dnf AS team_dnfs,
    ROUND((cs.race_dnf::numeric / NULLIF(cs.constructor_race_entries, 0)) * 100, 2) AS team_dnf_rate

FROM gold.v_analytics_constructor_season_stats cs
LEFT JOIN gold.v_analytics_constructor_standings cst 
    ON cs.constructor_id = cst.constructor_id AND cs.year = cst.year
LEFT JOIN gold.v_analytics_race_evolution re 
    ON cs.constructor_id = re.constructor_id AND cs.year = re.year AND re.session_type = 'RACE'
GROUP BY cs.year, cs.constructor_id, cs.constructor_name, cs.regulation_era, cst.season_position,
		cs.official_season_points, cs.constructor_race_entries, cs.race_wins, cs.race_podiums, 
		cs.race_dnf;