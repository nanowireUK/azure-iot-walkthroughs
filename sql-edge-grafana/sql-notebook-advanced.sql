IF OBJECT_ID('[dbo].[TempCompressedTable]', 'U') IS NOT NULL
DROP TABLE [dbo].[TempCompressedTable]
GO
-- Create the table in the specified schema
CREATE TABLE [dbo].[TempCompressedTable]
(
    [Id] INT NOT NULL IDENTITY PRIMARY KEY,
    [SensorId] NVARCHAR(255) NOT NULL, -- Primary Key column
    [TimeStart] DATETIME NOT NULL,
    [TimeEnd] DATETIME NOT NULL,
    [AvgMachineTemperature] FLOAT NOT NULL,
    [AvgMachinePressure] FLOAT NOT NULL,
    [AvgAmbientTemperature] FLOAT NOT NULL,
    [AvgAmbientHumidity] FLOAT NOT NULL
    -- Specify more columns here
);
GO

CREATE EXTERNAL STREAM StreamOutput 
WITH 
(
    DATA_SOURCE = EdgeHubInput,
    FILE_FORMAT = InputFileFormat,
    LOCATION = N'streamoutput',
    INPUT_OPTIONS = N'',
    OUTPUT_OPTIONS = N''
);
GO

CREATE EXTERNAL STREAM TempCompressedTableStream
WITH 
(
    DATA_SOURCE = LocalSQLOutput,
    LOCATION = N'SQLEdgeTest.dbo.TempCompressedTable',
    INPUT_OPTIONS = N'',
    OUTPUT_OPTIONS = N''
);
GO

EXEC sys.sp_create_streaming_job @name=N'TempSensorStreamJob',@statement= N'
WITH AvgQuery AS (
SELECT 
    MIN(timeCreated) as TimeStart,
    MAX(timeCreated) as TimeEnd,
    ''Test'' AS SensorId, 
    AVG(machine.temperature) AS AvgMachineTemperature,
    AVG(machine.pressure)    AS AvgMachinePressure,
    AVG(ambient.temperature) AS AvgAmbientTemperature,
    AVG(ambient.humidity)    AS AvgAmbientHumidity
FROM TempSensorStream TIMESTAMP BY timeCreated
GROUP BY SensorId, TumblingWindow(minute, 1) )

SELECT 
    timeCreated, 
    machine.temperature AS MachineTemperature,
    machine.pressure    AS MachinePressure,
    ambient.temperature AS AmbientTemperature,
    ambient.humidity    AS AmbientHumidity
INTO TempSensorTableStream
FROM TempSensorStream  TIMESTAMP BY timeCreated

SELECT * INTO StreamOutput
FROM AvgQuery

SELECT * INTO TempCompressedTableStream
FROM AvgQuery
'

exec sys.sp_stop_streaming_job @name=N'TempSensorStreamJob'
exec sys.sp_drop_streaming_job @name=N'TempSensorStreamJob'
exec sys.sp_start_streaming_job @name=N'TempSensorStreamJob'

SELECT TOP (1000) *
FROM [SQLEdgeTest].[dbo].[TempCompressedTable]
ORDER BY timeStart DESC