IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RMD_WAREHOUSE' AND COLUMN_NAME = 'allowNegativeStock')
ALTER TABLE RMD_WAREHOUSE ADD  allowNegativeStock BIT DEFAULT 0 WITH VALUES