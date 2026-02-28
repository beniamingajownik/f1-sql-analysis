# LAYER DESCRIPTION

## SILVER LAYER / WAREHOUSE 
- **`v_driver_base`**
    - Normalized view providing cleaned driver results, basic biography info, and unified session types across all eras.
- **`v_driver_championship_logic`**
    - Implements historical points systems and seasonal ranking logic to calculate cumulative driver standings.
- **`v_constructor_base`**
    - Normalized view for constructor results, unifying team data, engine manufacturers, and technical identifiers.
- **`v_constructor_championship_logic`**
    - Implements historical points systems and seasonal ranking logic to calculate cumulative constructor standings.

## GOLD LAYER / MARTS
- **`v_analytics_driver_standings`** 
    - Final seasonal driver rankings, providing championship positions and year-end point totals.
- **`v_analytics_constructor_standings`** 
    - Final seasonal constructor rankings, providing championship positions and year-end point totals.
- **`v_analytics_driver_career_summary`** 
    - Full career aggregates (Total wins, podiums, starts, DNF rate). Powers the Achievements dashboard section.
- **`v_analytics_constructor_career_summary`** 
    - Comprehensive team career aggregates (Total wins, podiums, starts, DNF rate). Powers the Achievements dashboard section.
- **`v_analytics_driver_season_stats`** 
    - Seasonal performance metrics (Avg start position, points per race, consistency). Powers the Performance analysis section.
- **`v_analytics_constructor_season_stats`** 
    - Team-level seasonal performance metrics, mirroring the driver stats for constructor-focused analysis.
- **`v_analytics_race_evolution`** 
    - Detailed position delta data (Grid vs Finish) enhanced with rolling averages and volatility metrics. Powers the Race Dynamics section.

---

# ANALYSIS SECTIONS

## 1. Driver Performance  

### Performance by *season*
`Navigate to analysis code` -> **[driver_performance_per_season.sql](https://github.com/beniamingajownik/f1-sql-analysis/tree/main/analysis/01_driver_performance/driver_performance_per_season.sql)**
1. Percentage of race victories  
2. Percentage of race podiums    
3. Percentage of sprint victories
4. Percentage of sprint podiums  
5. Highest average points 
6. Driver points trend over time *(year-over-year)*

### Performance *all time*
`Navigate to analysis code` -> **[driver_performance_all_time.sql](https://github.com/beniamingajownik/f1-sql-analysis/tree/main/analysis/01_driver_performance/driver_performance_all_time.sql)**
1. Percentage of race victories
2. Percentage of race podiums
3. Average starting position vs average finishing position throughout career *(minimum 30 race entries)*   
4. Biggest percent of total points *(% out of all available points earned by all drivers) [biggest domination all time]*
5. Smallest percent of total points *(% out of all available points earned by all drivers) [closests seasons all time]* 
6. Top 5 biggest point gaps between champion and runner-up 
7. Top 5 smallest point gaps between champion and runner-up 
8. Top 50 average position gain *(minimum 30 race entries)*

### Performance by *regulation era*
`Navigate to analysis code` -> **[driver_performance_by_era.sql](https://github.com/beniamingajownik/f1-sql-analysis/tree/main/analysis/01_driver_performance/driver_performance_by_era.sql)**
1. Biggest point gaps between champion and runner-up *(Biggest domination in an era)*
2. Smallest point gaps between champion and runner-up *(Closest title fights in an era)*
3. Best average position gain by a driver in a regulation era *(minimum 30 race entries)* 
4. Highest win count by driver
5. Average position gain *(minimum 30 race entries and avg_race_grid BETWEEN 5 AND 15)*

---
## 2. Constructor Performance         

### Performance by *season*
`Navigate to analysis code` -> **[constructor_performance_per_season.sql](https://github.com/beniamingajownik/f1-sql-analysis/tree/main/analysis/02_constructor_performance/constructor_performance_per_season.sql)**
1. Percentage of race victories  
2. Percentage of race podiums    
3. Percentage of sprint victories
4. Percentage of sprint podiums 
5. Percentage of 'One-Two' finishes
6. Highest average points 
7. Constructor points trend over time *(year-over-year)*
8. Driver contribution to team points (% contribution)
9. Comparison of drivers within the same team

### Performance *all time*
`Navigate to analysis code` -> **[constructor_performance_all_time.sql](https://github.com/beniamingajownik/f1-sql-analysis/tree/main/analysis/02_constructor_performance/constructor_performance_all_time.sql)**
1. Percentage of race victories
2. Percentage of race podiums
3. Average starting position vs average finishing position throughout career *(minimum 30 race entries)*   
4. Constructor points market share
5. Top 10 biggest point gaps between champion and runner-up 
6. Top 10 smallest point gaps between champion and runner-up 

### Performance by *regulation era*
`Navigate to analysis code` -> **[constructor_performance_by_era.sql](https://github.com/beniamingajownik/f1-sql-analysis/tree/main/analysis/02_constructor_performance/constructor_performance_by_era.sql)**
1. Biggest point gaps between champion and runner-up *(Biggest domination in an era)*
2. Smallest point gaps between champion and runner-up *(Closest title fights in an era)*
3. Best average position gain by a constructor in a regulation era *(minimum 30 race entries)* 
4. Highest win % by constructor
5. Biggest % of total points *(% out of all available points earned by all constructors) [biggest domination]*
6. Era competitiveness *(how close were constructors points-wise to eachother)*

---

## 3. Race dynamics

### Driver
`Navigate to analysis code` -> **[driver_race_dynamics.sql](https://github.com/beniamingajownik/f1-sql-analysis/tree/main/analysis/03_race_dynamics/driver_race_dynamics.sql)**
1. Highest average position gain in a season *(Driver Overtaking Efficiency)*
2. Highest average position gain in an era *(Driver Overtaking Efficiency)*
3. Qualifying Volatility in a season
4. Race finish position volatility in a season
5. Race finish position volatility in an era
6. Qualifying position improvement in a season *(Mid-Season Progress)*
7. Race position improvement in a season *(Mid-Season Progress)*
8. Race position improvement in an era *(Mid-Season Progress)*
9. Season race position stability *(Stability of results across a Season)*
10. Era race position stability *(Stability of results across Regulation Eras)*

### Constructor
`Navigate to analysis code` -> **[constructor_race_dynamics.sql](https://github.com/beniamingajownik/f1-sql-analysis/tree/main/analysis/03_race_dynamics/constructor_race_dynamics.sql)**
1. Highest average position gain in a season *(Constructor Overtaking Efficiency)*
2. Highest average position gain in an era *(Constructor Overtaking Efficiency)*
3. Qualifying Volatility in a season
4. Race finish position volatility in a season
5. Race finish position volatility in an era
6. Qualifying position improvement in a season *(Mid-Season Progress)*
7. Race position improvement in a season *(Mid-Season Progress)*
8. Race position improvement in an era *(Mid-Season Progress)*
9. Season race position stability *(Stability of results across a Season)*
10. Era race position stability *(Stability of results across Regulation Eras)*

---

## 4. Consistency

### Driver
`Navigate to analysis code` -> **[driver_consistency.sql](https://github.com/beniamingajownik/f1-sql-analysis/tree/main/analysis/04_consistency_trends/driver_consistency.sql)**
1. Most consistent drivers in Main Races *(Mean Absolute Deviation (MAD))*
2. Standard deviation of finishing positions
3. Number of consecutive points finishes
4. Longest streak of classified race finishes
5. Longest win streaks
6. Longest podium streaks

### Constructor
`Navigate to analysis code` -> **[constructor_consistency.sql](https://github.com/beniamingajownik/f1-sql-analysis/tree/main/analysis/04_consistency_trends/constructor_consistency.sql)**
1. Most consistent constructors in Main Races *(Mean Absolute Deviation (MAD))*
2. Standard deviation of finishing positions
3. Number of consecutive points finishes
4. Longest streak of classified race finishes
5. Longest win streaks
6. Longest podium streaks

---

## 5. Overall sport analysis 

## Driver Achievements
`Navigate to analysis code` -> **[driver_achievements.sql](https://github.com/beniamingajownik/f1-sql-analysis/tree/main/analysis/05_overall_sporting_analysis/driver_achievements.sql)**
1. Count of WDC titles per each champion
2. Count of race victories   
3. Count of race podiums     
4. Count of sprint victories 
5. Count of sprint podiums  

## Constructor Achievements
`Navigate to analysis code` -> **[constructor_achievements.sql](https://github.com/beniamingajownik/f1-sql-analysis/tree/main/analysis/05_overall_sporting_analysis/constructor_achievements.sql)**
1. Count of constructor titles per each champion 
2. Count of race victories         
3. Count of race podiums             
4. Count of sprint victories         
5. Count of sprint podiums  

### General Achievements
`Navigate to analysis code` -> **[general_achievements.sql](https://github.com/beniamingajownik/f1-sql-analysis/tree/main/analysis/05_overall_sporting_analysis/general_achievements.sql)**
1. Count of World Drivers Champion (WDC) titles per country   
2. Count of World Drivers Champion (WDC) titles per continent  

### Reliability Performance
`Navigate to analysis code` -> **[reliability.sql](https://github.com/beniamingajownik/f1-sql-analysis/tree/main/analysis/05_overall_sporting_analysis/reliability.sql)**
1. Total DNFs per driver all-time *(minimum 30 race entries)*
2. Driver race finish rate *(% of races finished per season)*
3. Driver DNF rate *(% of DNFs per season)*
4. Driver DNF rate *(% of DNFs per era)*
5. Total DNFs per constructor all-time *(minimum 60 race entries)*
6. Constructor race finish rate *(% of races finished per season)*
7. Constructor DNF rate *(% of DNFs per season)*
8. Constructor DNF rate *(% of DNFs per era)*
9. Total DNFs per regulation era *(minimum 30 race entries)*