IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'JewelleryDetail')
   AND NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'JewelleryDetail' AND COLUMN_NAME ='luxuryTaxable')
ALTER TABLE JewelleryDetail ADD luxuryTaxable DECIMAL(24,12) NOT NULL DEFAULT (0) WITH VALUES

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'JewelleryDetail')
   AND NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'JewelleryDetail' AND COLUMN_NAME ='luxuryTax')
ALTER TABLE JewelleryDetail ADD luxuryTax DECIMAL(24,12) NOT NULL DEFAULT (0) WITH VALUES

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'JewelleryDetail')
   AND NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'JewelleryDetail' AND COLUMN_NAME ='flatDiscount')
ALTER TABLE JewelleryDetail ADD flatDiscount DECIMAL(24,12) NOT NULL DEFAULT (0) WITH VALUES