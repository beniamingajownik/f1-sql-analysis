## ⚙️ Setup & Installation

This project is fully containerized using Docker to ensure a seamless setup experience without the need for manual database configuration. The environment includes a **PostgreSQL 18.3-alpine** database and a web-based **pgAdmin4** interface.

### **Prerequisites**
* [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running.
* The raw data file `f1db-sql-postgresql-single-inserts.sql` (1950-2025) must be placed in the `data/source/` directory.

---

### Method 1: Manual SQL Import (pgAdmin / psql)

1. **Download Data**: 
    - Download the `f1db-sql-postgresql-single-inserts.sql` from [data/source](https://github.com/beniamingajownik/f1-sql-analysis/tree/main/data/source).
    - Download the `portfolio-sql-postgresql-single-inserts.sql` from [data/portfolio work](https://github.com/beniamingajownik/f1-sql-analysis/tree/main/data/portfolio-work).
2. **Import Data**: 
    - First run the `f1db-sql-postgresql-single-inserts.sql` file in your PostgreSQL tool (e.g., local pgAdmin, DBeaver, or DataGrip) to populate the raw tables.
    - Then run the `portfolio-sql-postgresql-single-inserts.sql` file in your PostgreSQL tool to create silver and gold layer views.  

### **Method 2: Automated Deployment (Docker)**

1.  **Clone repo / download**:
    ```bash
    git clone https://github.com/beniamingajownik/f1-sql-analysis.git
    ```
2.  **Launch the Environment**:
    Navigate to the `installation/docker/` directory in your terminal and run:
    ```bash
    docker-compose up -d
    ```
    *This command will pull the images, initialize the database, and automatically execute the following scripts in order:*
    * `01_source_data.sql`: Imports the raw historical F1 data.
    * `02_setup_layers.sql`: Builds the Silver and Gold analytical layers (Views).

3.  **Access the Analytics UI**:
    Open your browser and navigate to: **`http://localhost:5050`**.
    * **Email**: `admin@bgportfolio.com`
    * **Password**: `admin`

4.  **Register the F1 Server in pgAdmin**:
    Inside the web-based pgAdmin, register the internal Docker server to view the data:
    * **Host name/address**: `bg_portfolio` (internal service name)
    * **Port**: `5432` (internal container port)
    * **Maintenance database**: `f1_portfolio_db`
    * **Username**: `f1_user`
    * **Password**: `f1_pass`

---

### **Method 3: Manual Local Connection (Docker)**

If you prefer to use a standalone SQL client (e.g., local pgAdmin, DBeaver, or DataGrip), use the following credentials to connect to the Docker container:
* **Host**: `localhost`
* **Port**: `5433` (externally mapped port)
* **Database**: `f1_portfolio_db`
* **User/Pass**: `f1_user` / `f1_pass`

---

### **📂 Important Notes**
* **Schema Visibility**: Historical data from is located in the **`public`** schema. Silver and Gold layer views are located across the **`silver`** and **`gold`** schemas respectively.
* **Initialization Time**: The initial import of over 75 years of data may take 1-2 minutes depending on your hardware. You can monitor the progress by running:
  ```bash
  docker logs -f portfolio_db
  ```