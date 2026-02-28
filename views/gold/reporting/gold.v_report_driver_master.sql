/*
VIEW: gold.v_report_driver_master
PURPOSE:
    - Provides a centralized, Power BI-ready table for driver seasonal performance analysis.
    - Serves as the primary source for "Driver Performance", "Consistency", and "Race Dynamics" dashboard sections.
	
KEY BUSINESS & DATA LOGIC:
    - Consolidates seasonal rankings (WDC) with performance metrics and reliability data.
    - Features a Season Momentum Index to track driver adaptation and performance trends relative to the seasonal average.
    - Integrates Overtaking Efficiency (avg_pos_gain) and Volatility metrics (SD) to measure qualifying and race-day stability.
    - Uses a seasonal grain, making it ideal for year-over-year comparisons and trend analysis.

DATA HIERARCHY & GRAIN:
    - Granularity: One row per driver per season (Year)

SOURCE TABLES:
    - gold.v_analytics_driver_season_stats
    - gold.v_analytics_driver_standings
    - gold.v_analytics_race_evolution
*/

CREATE OR REPLACE VIEW gold.v_report_driver_master AS

SELECT 
    -- 1. Identity & Context
    ds.year,
    ds.driver_id,
    ds.driver_name,
    ds.team AS constructor_name,
    ds.regulation_era,

    -- 2. Performance (Achievements & Standings)
    st.season_position AS wdc_position,
    CASE WHEN st.season_position = 1 THEN 1 ELSE 0 END AS is_wdc_champion,
    ds.official_season_points,
    ds.season_race_entries,
    ds.race_wins,
    ds.race_podiums,
    ROUND((ds.race_wins::numeric / NULLIF(ds.season_race_entries, 0)) * 100, 2) AS race_win_pct,
    ROUND((ds.race_podiums::numeric / NULLIF(ds.season_race_entries, 0)) * 100, 2) AS race_podium_pct,

    -- 3. Race Dynamics
    ROUND(AVG(re.grid_position - re.finish_position), 0) AS avg_pos_gain,
    ROUND(AVG(re.driver_cum_stddev_grid), 3) AS qualy_volatility,
    ROUND(AVG(re.driver_cum_stddev_finish), 3) AS race_consistency,
    ROUND(AVG(re.driver_finish_season_delta), 3) AS season_momentum_index,

    -- 4. Reliability
    ds.race_dnf AS total_dnfs,
    ROUND((1 - (ds.race_dnf::numeric / NULLIF(ds.season_race_entries, 0))) * 100, 2) AS finish_rate_pct

FROM gold.v_analytics_driver_season_stats ds
LEFT JOIN gold.v_analytics_driver_standings st 
    ON ds.driver_id = st.driver_id AND ds.year = st.year
LEFT JOIN gold.v_analytics_race_evolution re 
    ON ds.driver_id = re.driver_id AND ds.year = re.year AND re.session_type = 'RACE'
GROUP BY 
    ds.year, ds.driver_id, ds.driver_name, ds.team, ds.regulation_era, 
    st.season_position, ds.official_season_points, ds.season_race_entries, 
    ds.race_wins, ds.race_podiums, ds.race_dnf;