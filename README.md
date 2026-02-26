# Creating reporting layer in DWH for BI 

This repository covers the implementation of a required test task for internship.

The provided code showcases the design and implementation of an ETL pipeline that handles schema setup, mock data insertion, and data processing from source tables to the datamart, including incremental loading and data quality handling and logging.

## Documentation

A explanation of the key aspects of the solution design, approach and rationale is provided in [Documentation]([https://github.com/markomilosevic9/](https://github.com/markomilosevic9/creating-reporting-layer-in-dwh-for-bi/blob/main/Documentation.pdf)) PDF file.


The document includes:
- Data modeling approach  
- Description of data processing workflow 
- Description of data quality-related approach and considerations
- Analytical queries 

All diagrams included in the documentation are also available in high resolution within the repository (e.g., `picture_1`, `picture_2`, etc.).

## The pipeline
The pipeline logic is placed within few .sql scripts meant to be executed one-by-one:

```bash
└───sql
        sql/schema_init.sql - initializes schemas and tables
        sql/first_mock_data_insert.sql - insertion of initial, mock data sample
        sql/etl_pipeline.sql - main pipeline script
        sql/second_mock_data_incremental_insert.sql - insertion of incremental data sample
        sql/analytical_queries.sql - provides analytical queries 
```
Note that after loading of incremental mock data sample, the re-execution of `etl_pipeline.sql` script is required.

## Running the pipeline

After cloning the repository or downloading files, you can run the pipeline using Docker. To do so, you can execute following commands in sequence.

From the project root directory:

```bash
docker-compose up -d
```
Then:

```bash
docker exec -i pg-storage psql -U storage -d project_data < sql/schema_init.sql
docker exec -i pg-storage psql -U storage -d project_data < sql/first_mock_data_insert.sql
docker exec -i pg-storage psql -U storage -d project_data < sql/etl_pipeline.sql
docker exec -i pg-storage psql -U storage -d project_data < sql/second_mock_data_incremental_insert.sql
docker exec -i pg-storage psql -U storage -d project_data < sql/etl_pipeline.sql
docker exec -i pg-storage psql -U storage -d project_data < sql/analytical_queries.sql

```

These commands create DB schemas and tables, insert initial mock data sample, run the pipeline, insert incremental mock data sample and re-run the pipeline to simulate the incremental loading. 

Also, after launching Docker container, you can connect to PostgreSQL instance via e.g. DBeaver using following parameters:
```
Host: localhost
Port: 5433
DB: project_data
Username: storage
Password: storage
```

Once connected, you can execute the SQL scripts manually in the same order as described above.

Please note: Docker is used just to simplify environment setup and it is not required. The solution itself can be executed on any PostgreSQL instance, after creation of DB (e.g. project_data), successful connection and execution of SQL scripts in aforementioned order.


