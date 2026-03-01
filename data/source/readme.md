# 📥 SOURCE DATA

This directory contains the foundational dataset used for this project. 

### 📄 File: `f1db-sql-postgresql-single-inserts.sql`

This PostgreSQL dump is sourced directly from the **f1db project** (The Open Source Formula 1 Database). It provides the comprehensive raw data covering the history of Formula 1, including drivers, constructors, circuits, and race results.

**Note:** This file serves as the **Bronze Layer** (Raw Data) in our pipeline. All original credit for the collection and maintenance of this data goes to the creators of [f1db](https://github.com/f1db/f1db). 

The transformation logic, analytical views, and reporting structures developed on top of this dataset can be found in the [`views/`](https://github.com/beniamingajownik/f1-sql-analysis/tree/main/views) and [`data/portfolio-work/`](https://github.com/beniamingajownik/f1-sql-analysis/tree/main/data/portfolio%20work) directories.