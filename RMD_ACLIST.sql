IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RMD_ACLIST' AND COLUMN_NAME = 'BlockNegativeBalance')
ALTER TABLE RMD_ACLIST ADD BlockNegativeBalance TINYINT NOT NULL, 
CONSTRAINT DF_RMD_ACLIST_BlockNegativeBalance DEFAULT (0) FOR BlockNegativeBalance WITH VALUES

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RMD_ACLIST' AND COLUMN_NAME = 'PMODE')
ALTER TABLE RMD_ACLIST ADD PMODE VARCHAR(50) NULL

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '_LOG_RMD_ACLIST' AND COLUMN_NAME = 'PMODE')
ALTER TABLE _LOG_RMD_ACLIST ADD PMODE VARCHAR(50) NULL