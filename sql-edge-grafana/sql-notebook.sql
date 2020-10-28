-- Create a new database called 'SQLEdgeTest'
    -- Connect to the 'master' database to run this snippet
    USE master
    GO
    -- Create the new database if it does not exist already
    IF NOT EXISTS (
        SELECT [name]
            FROM sys.databases
            WHERE [name] = N'SQLEdgeTest'
    )
    CREATE DATABASE SQLEdgeTest
    GO

-- Connect to new database instead of master
    USE SQLEdgeTest
    go

-- Defining the Edge Hub input Stream
-- Create a new query and run the following in turn as per https://docs.microsoft.com/en-us/azure/azure-sql-edge/create-stream-analytics-job#example-create-an-external-stream-inputoutput-object-for-azure-iot-edge-hub
    Create External file format InputFileFormat
    WITH 
    (  
    format_type = JSON,
    )
    go

    CREATE EXTERNAL DATA SOURCE EdgeHubInput 
    WITH 
    (
        LOCATION = 'edgehub://'
    )
    go

    CREATE EXTERNAL STREAM TempSensorStream 
    WITH 
    (
        DATA_SOURCE = EdgeHubInput,
        FILE_FORMAT = InputFileFormat,
        LOCATION = N'TempSensorStream',
        INPUT_OPTIONS = N'',
        OUTPUT_OPTIONS = N''
    );
    go

-- Creating the table
    IF OBJECT_ID('[dbo].[TempSensorTable]', 'U') IS NOT NULL
    DROP TABLE [dbo].[TempSensorTable]
    GO
    CREATE TABLE [dbo].[TempSensorTable]
    (
        [Id] INT NOT NULL IDENTITY PRIMARY KEY, -- Primary Key column
        [timeCreated] DATETIME NOT NULL,
        [MachineTemperature] FLOAT NOT NULL,
        [MachinePressure] FLOAT NOT NULL,
        [AmbientTemperature] FLOAT NOT NULL,
        [AmbientHumidity] FLOAT NOT NULL
    );
    GO

-- Create the SQL Output Stream
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'sdflkijsd%%#@#$ddff789897ono3nd';

    CREATE DATABASE SCOPED CREDENTIAL SQLCredential
    WITH IDENTITY = 'sa', SECRET = '<Default_MSSQL_SA_Password>'
    go

    CREATE EXTERNAL DATA SOURCE LocalSQLOutput 
    WITH 
    (
        LOCATION = 'sqlserver://tcp:.,1433',
        CREDENTIAL = SQLCredential
    )
    go

    CREATE EXTERNAL STREAM TempSensorTableStream
    WITH 
    (
        DATA_SOURCE = LocalSQLOutput,
        LOCATION = N'SQLEdgeTest.dbo.TempSensorTable',
        INPUT_OPTIONS = N'',
        OUTPUT_OPTIONS = N''
    );

-- Create the streaming job
    EXEC sys.sp_create_streaming_job @name=N'TempSensorStreamJob',@statement= N'
    SELECT 
        timeCreated, 
        machine.temperature AS MachineTemperature,
        machine.pressure AS MachinePressure,
        ambient.temperature AS AmbientTemperature,
        ambient.humidity AS AmbientHumidity
    INTO TempSensorTableStream
    FROM TempSensorStream'

    exec sys.sp_start_streaming_job @name=N'TempSensorStreamJob'
    go

-- Monitor the job
    exec sys.sp_get_streaming_job @name=N'TempSensorStreamJob'
    WITH RESULT SETS
    (
        (
        name nvarchar(256),
        status nvarchar(256),
        error nvarchar(256)
        )
    )