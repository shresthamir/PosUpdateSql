
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SALESMAN' AND COLUMN_NAME = 'IsActive')
BEGIN
    DECLARE @SQL nVARCHAR(MAX)
    SELECT @SQL = 'ALTER TABLE ' + OBJECT_NAME(parent_object_id) 
                + ' DROP CONSTRAINT ' + d.name + '; '
    FROM sys.default_constraints d 
    JOIN sys.columns c ON d.parent_object_id = c.object_id AND d.parent_column_id = c.column_id 
    WHERE OBJECT_NAME(parent_object_id) = 'SalesMan' AND C.name = 'IsActive';
    print @SQL
    IF @SQL is not NULL
        EXEC sp_executesql @SQL;
    ALTER TABLE SALESMAN DROP COLUMN IsActive;
END 

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SALESMAN' AND COLUMN_NAME = 'Status')
ALTER TABLE SALESMAN ADD [Status] BIT NOT NULL DEFAULT(1) WITH VALUES