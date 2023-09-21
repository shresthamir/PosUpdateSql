IF EXISTS( SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '_LOG_BARCODE' AND  COLUMNPROPERTY(OBJECT_ID('_LOG_BARCODE'), COLUMN_NAME, 'IsIdentity') = 1)
DROP TABLE _LOG_BARCODE

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '_LOG_BARCODE')
SELECT 0 LOGID, GETDATE() LOGDATE, CAST('' AS VARCHAR(50)) LOGUSER, CAST('E' AS CHAR(1)) LOGACTION, * INTO _LOG_BARCODE FROM BARCODE WHERE 0 = 1
UNION ALL
SELECT 0 LOGID, GETDATE() LOGDATE, CAST('' AS VARCHAR(50)) LOGUSER, CAST('E' AS CHAR(1)) LOGACTION, * FROM BARCODE WHERE 0 = 1

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '_LOG_BARCODE' AND COLUMN_NAME = 'LOID')
EXEC sp_RENAME '_LOG_BARCODE.LOID' , 'LOGID', 'COLUMN'

IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '_LOG_BARCODE' AND COLUMN_NAME = 'SN' AND IS_NULLABLE = 'NO')
ALTER TABLE _LOG_BARCODE ALTER COLUMN SN NUMERIC(18,0) NULL

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '_LOG_BARCODE' AND COLUMN_NAME = 'BAR_DISRATE')
ALTER TABLE _LOG_BARCODE ADD BAR_DISRATE DECIMAL(5,2) NULL

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '_LOG_BARCODE' AND COLUMN_NAME = 'ISACTIVE')
ALTER TABLE _LOG_BARCODE ADD ISACTIVE TINYINT NULL