IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'PDF_PRINT_CONFIG' AND COLUMN_NAME = 'formatName')
ALTER TABLE PDF_PRINT_CONFIG ADD formatName VARCHAR(20) NULL