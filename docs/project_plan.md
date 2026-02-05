# Project Plan: F1 SQL Analysis

## Primary goal
-   Analyze the results of Formula 1 drivers and teams performance using a consolidated race-by-race dataset.

    ### Key areas of analysis
    - driver performance
    - constructor effectiveness 
    - race dynamics
    - performance consistency over time

## Secondary goal
-   Create a robust and scalable data pipeline in SQL, leveraging advanced data preparation techniques to ensure seamless integration and high performance in Power BI. 

---

## Project Layers
-   **[DONE] Base Layer:** `v_driver_base` - Cleaned facts at driver x session grain.
-   **[TODO] Logic Layer:** `v_driver_championship_logic` - Historical rules and championship eligibility (dropped results).
-   **[TODO] Analytics Layer:** Aggregated standings, driver performance KPIs, and era-based comparisons.

---

## Completed Milestones
-   **[SETUP]** **Database Setup**: Successfully imported the F1 historical dataset.
-   **[SETUP]** **Project Architecture**: Implemented a layered folder structure (Base/Logic/Analytics) to ensure scalability and Clean Code standards.
-   **[BASE]** **Base Layer (Silver)**: Developed the `v_driver_base` view, which includes:
        - Categorization by technical **Regulation Eras**.
        - **DNS (Did Not Start)** and **DNF** flagging for reliability analysis.
        - **Pit Lane start** logic and grid position normalization.

## Milestones In Progress
-   **[LOGIC]** **Championship Logic & Standing**: Developing the `v_driver_championship_logic` view:
        - Apply "Dropped Results" logic for 1950-1990 seasons.
        - Handle "Shared Drives" (taking MIN position_number per driver/race).
-   **[ANALYTICS]** **Driver consistency metrics**: Seasonal statistics (Average points, Main Race vs. Sprint Race performance split, grid position vs finish position etc.). *Dependent on Logic Layer completion*
-   **[ANALYTICS]** **Career Milestones Analysis**: Building views to track driver life-cycles (age at first win, days from debut to first points, etc.). *Dependent on Logic Layer completion*
-   **[VERYFICATION]** **Data Quality Audit**: Cross-referencing calculated standings with official FIA year-end results to ensure logic accuracy.   
-   **[VISUALIZATION]** **PowerBI Visualization**
    
## Tech Stack
-    PostgreSQL 
-    Power BI  
-    Git (PowerShell)
