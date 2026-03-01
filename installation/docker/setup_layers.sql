CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

-- ==========================================================
-- STEP 1: BASE VIEWS (Silver Layer)
-- ==========================================================
\i /repo_data/views/silver/base/silver.v_driver_base.sql
\i /repo_data/views/silver/base/silver.v_constructor_base.sql

-- ==========================================================
-- STEP 2: CHAMPIONSHIP LOGIC (Silver Layer)
-- ==========================================================
\i /repo_data/views/silver/logic/silver.v_driver_championship_logic.sql
\i /repo_data/views/silver/logic/silver.v_constructor_championship_logic.sql

-- ==========================================================
-- STEP 3: ANALYTICS MARTS (Gold Layer)
-- ==========================================================
\i /repo_data/views/gold/analytics/gold.v_analytics_constructor_standings.sql
\i /repo_data/views/gold/analytics/gold.v_analytics_driver_standings.sql
\i /repo_data/views/gold/analytics/gold.v_analytics_constructor_season_stats.sql
\i /repo_data/views/gold/analytics/gold.v_analytics_race_evolution.sql
\i /repo_data/views/gold/analytics/gold.v_analytics_driver_season_stats.sql
\i /repo_data/views/gold/analytics/gold.v_analytics_driver_career_summary.sql
\i /repo_data/views/gold/analytics/gold.v_analytics_constructor_career_summary.sql

-- ==========================================================
-- STEP 4: REPORTING MASTER VIEWS (Gold Layer)
-- ==========================================================
\i /repo_data/views/gold/reporting/gold.v_report_constructor_master.sql
\i /repo_data/views/gold/reporting/gold.v_report_driver_master.sql
\i /repo_data/views/gold/reporting/gold.v_report_hall_of_fame_master.sql