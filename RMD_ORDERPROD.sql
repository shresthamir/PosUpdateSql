IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RMD_ORDERPROD' AND COLUMN_NAME = 'ISVAT')
ALTER TABLE RMD_ORDERPROD ADD ISVAT TINYINT NOT NULL, CONSTRAINT DF_RMD_ORDERPROD_ISVAT DEFAULT (0) FOR ISVAT WITH VALUES

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RMD_ORDERPROD' AND COLUMN_NAME = 'VAT')
ALTER TABLE RMD_ORDERPROD ADD VAT NUMERIC(22,12) NOT NULL, CONSTRAINT DF_RMD_ORDERPROD_VAT DEFAULT (0) FOR VAT WITH VALUES

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RMD_ORDERPROD' AND COLUMN_NAME = 'INDDISCOUNTRATE')
ALTER TABLE RMD_ORDERPROD ADD INDDISCOUNTRATE NUMERIC(6,4) NOT NULL, CONSTRAINT DF_RMD_ORDERPROD_INDDISCOUNTRATE DEFAULT (0) FOR INDDISCOUNTRATE WITH VALUES

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RMD_ORDERMAIN' AND COLUMN_NAME = 'STATUS')
ALTER TABLE RMD_ORDERMAIN ADD [STATUS] TINYINT, CONSTRAINT DF_RMD_ORDERMAIN_STATUS DEFAULT (0) FOR [STATUS] WITH VALUES

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LOGPROD_ORDER' AND COLUMN_NAME = 'ISVAT')
ALTER TABLE LOGPROD_ORDER ADD ISVAT TINYINT

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LOGPROD_ORDER' AND COLUMN_NAME = 'VAT')
ALTER TABLE LOGPROD_ORDER ADD VAT NUMERIC(22,12)

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LOGPROD_ORDER' AND COLUMN_NAME = 'INDDISCOUNTRATE')
ALTER TABLE LOGPROD_ORDER ADD INDDISCOUNTRATE NUMERIC(6,4)

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LOGPROD_ORDER' AND COLUMN_NAME = 'INDDISCOUNT')
ALTER TABLE LOGPROD_ORDER ADD INDDISCOUNT NUMERIC(22,12)

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LOGPROD_ORDER' AND COLUMN_NAME = 'FLATDISCOUNT')
ALTER TABLE LOGPROD_ORDER ADD FLATDISCOUNT NUMERIC(22,12)

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RMD_ORDERMAIN' AND COLUMN_NAME = 'MEMBERNO')
ALTER TABLE RMD_ORDERMAIN ADD MEMBERNO VARCHAR(25)

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RMD_ORDERMAIN' AND COLUMN_NAME = 'DeliveryChannel')
ALTER TABLE RMD_ORDERMAIN ADD DeliveryChannel VARCHAR(25)

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RMD_ORDERMAIN' AND COLUMN_NAME = 'ORDER_SOURCE')
ALTER TABLE RMD_ORDERMAIN ADD ORDER_SOURCE VARCHAR(25)

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RMD_ORDERMAIN' AND COLUMN_NAME = 'CustomerName')
ALTER TABLE RMD_ORDERMAIN ADD CustomerName VARCHAR(25)

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RMD_ORDERMAIN' AND COLUMN_NAME = 'OrderChannel')
ALTER TABLE RMD_ORDERMAIN ADD OrderChannel VARCHAR(25)

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LOGMAIN_ORDER' AND COLUMN_NAME = 'STATUS')
ALTER TABLE LOGMAIN_ORDER ADD [STATUS] TINYINT

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LOGMAIN_ORDER' AND COLUMN_NAME = 'MEMBERNO')
ALTER TABLE LOGMAIN_ORDER ADD MEMBERNO VARCHAR(25)

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LOGMAIN_ORDER' AND COLUMN_NAME = 'DeliveryChannel')
ALTER TABLE LOGMAIN_ORDER ADD DeliveryChannel VARCHAR(25)

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LOGMAIN_ORDER' AND COLUMN_NAME = 'ORDER_SOURCE')
ALTER TABLE LOGMAIN_ORDER ADD ORDER_SOURCE VARCHAR(25)

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LOGMAIN_ORDER' AND COLUMN_NAME = 'CustomerName')
ALTER TABLE LOGMAIN_ORDER ADD CustomerName VARCHAR(25)

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LOGMAIN_ORDER' AND COLUMN_NAME = 'OrderChannel')
ALTER TABLE LOGMAIN_ORDER ADD OrderChannel VARCHAR(25)

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LOGMAIN_ORDER' AND COLUMN_NAME = 'TOTALFLATDISCOUNT')
ALTER TABLE LOGMAIN_ORDER ADD TOTALFLATDISCOUNT DECIMAL(20,12) NULL

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LOGMAIN_ORDER' AND COLUMN_NAME = 'SHIFT')
ALTER TABLE LOGMAIN_ORDER ADD SHIFT VARCHAR(20) NULL

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LOGMAIN_ORDER' AND COLUMN_NAME = 'DATA_ORIGIN')
ALTER TABLE LOGMAIN_ORDER ADD DATA_ORIGIN VARCHAR(20) NULL