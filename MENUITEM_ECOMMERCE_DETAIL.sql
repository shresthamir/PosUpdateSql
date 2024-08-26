IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'MENUITEM_ECOMMERCE_DETAIL')
CREATE TABLE [dbo].[MENUITEM_ECOMMERCE_DETAIL](
	[MCODE] [varchar](25) NOT NULL,
	[SyncToDaraz] [tinyint] NOT NULL,
	[OfferStartDate] [datetime] NULL,
	[OfferEndDate] [datetime] NULL,
	CONSTRAINT FK_MENUITEM_ECOMMERCE_DETAIL FOREIGN KEY (MCODE) REFERENCES MENUITEM(MCODE) ON DELETE CASCADE
) ON [PRIMARY]

IF NOT EXISTS(SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'MENUITEM' AND COLUMN_NAME = 'IsRecurringItem')
ALTER TABLE MENUITEM ADD IsRecurringItem BIT NOT NULL, CONSTRAINT DF_MENUITEM_IsRecurringItem DEFAULT (0) FOR IsRecurringItem WITH VALUES

IF NOT EXISTS(SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'MENUITEM' AND COLUMN_NAME = 'FolloupItem')
ALTER TABLE MENUITEM ADD FolloupItem VARCHAR(25)


IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'MENUITEM' AND COLUMN_NAME = 'Yield')
ALTER TABLE MENUITEM ADD Yield NUMERIC(5,2) NOT NULL, CONSTRAINT DF_MENUITEM_Yield DEFAULT (0) FOR Yield WITH VALUES

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'MENUITEM' AND COLUMN_NAME = 'ShelfLife')
ALTER TABLE MENUITEM ADD ShelfLife INT NOT NULL, CONSTRAINT DF_MENUITEM_ShelfLife DEFAULT (0) FOR ShelfLife WITH VALUES

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME ='MENUITEM' AND COLUMN_NAME = 'IsSyncedWithKDS')                                                     
ALTER TABLE MENUITEM  ADD IsSyncedWithKDS TINYINT NOT NULL, CONSTRAINT DF_MENUITEM_IsSyncedWithKDS DEFAULT (0) FOR IsSyncedWithKDS WITH VALUES

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME ='MENUITEM' AND COLUMN_NAME = 'IsSyncedWithQRMenu')                                                     
ALTER TABLE MENUITEM  ADD IsSyncedWithQRMenu TINYINT NOT NULL, CONSTRAINT DF_MENUITEM_IsSyncedWithQRMenu DEFAULT (0) FOR IsSyncedWithQRMenu WITH VALUES

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'MENUITEM' AND COLUMN_NAME = 'HasVariant')
ALTER TABLE MENUITEM ADD HasVariant TINYINT NOT NULL DEFAULT (0) WITH VALUES

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'MENUITEM' AND COLUMN_NAME = 'LuxuryTaxApplicable')
ALTER TABLE MENUITEM ADD LuxuryTaxApplicable BIT