IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'BARCODE_DETAIL' AND COLUMN_NAME = 'STAMP')
ALTER TABLE BARCODE_DETAIL ADD STAMP FLOAT NOT NULL, CONSTRAINT DF_BARCODE_DETAIL_STAMP DEFAULT (CONVERT(FLOAT, GETDATE())) FOR STAMP

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'BARCODE' AND COLUMN_NAME = 'ISDEACTIVE')
ALTER TABLE BARCODE ADD ISDEACTIVE BIT

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'BARCODE' AND COLUMN_NAME = 'BAR_DISRATE')
ALTER TABLE BARCODE ADD BAR_DISRATE DECIMAL(5,2) NOT NULL, CONSTRAINT DF_BARCODE_DISCOUNT DEFAULT(0) FOR BAR_DISRATE WITH VALUES

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'BARCODE' AND COLUMN_NAME = 'barcodeDetails')
ALTER TABLE BARCODE ADD barcodeDetails VARCHAR(MAX) NULL

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '_LOG_BARCODE' AND COLUMN_NAME = 'barcodeDetails')
ALTER TABLE _LOG_BARCODE ADD barcodeDetails VARCHAR(MAX) NULL