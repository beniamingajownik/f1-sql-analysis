# Project Plan: F1 SQL Analysis

## Primary goal
-   Analize the results of Formula 1 drivers and teams performance using a consolidated race-by-race dataset.

    ### Key areas of analysis
    - driver performance
    - constructor effectiveness 
    - race dynamics
    - performance consistency over time

## Secondary goal
-   Create a robust and scalable data pipeline in SQL, leveraging advanced data preparation techniques to ensure seamless integration and high performance in Power BI. 

---

## Completed Milestones
-  **Database Setup**: Successfully imported the F1 historical dataset.
-  **Project Architecture**: Implemented a layered folder structure (Base/Reporting/Exploratory) to ensure scalability and Clean Code standards.
-  **Base Layer (Silver)**: Developed the `v_driver_base` view, which includes:
    - Categorization by technical **Regulation Eras**.
    - **DNS (Did Not Start)** and **DNF** flagging for reliability analysis.
    - **Pit Lane start** logic and grid position normalization.

## In Progress
-   **Reporting Layer (Gold)**: Developing the `v_analysis_driver_season_performance` view:
    - Seasonal statistics (Average points, Race vs. Sprint performance split).
    - Driver championship rankings using `DENSE_RANK`.
-   **Career Milestones Analysis**: Building views to track driver life-cycles (age at first win, days from debut to first points, etc.).
-   **Data Quality Audit**: Verifying historical data consistency across different eras.

## Upcoming Steps
1. Finalize Driver Career Milestones analysis.
2. Initiate Constructor Performance analysis (`02_constructor_performance`).
3. Develop a dedicated SQL suite for Power BI dashboard integration.
