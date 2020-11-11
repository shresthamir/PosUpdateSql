IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'CategoryWiseMonthlySalesPlan')
CREATE TABLE [dbo].[CategoryWiseMonthlySalesPlan](
	[Year] [varchar](4) NOT NULL,
	[Month] [varchar](2) NOT NULL,
	[Category] [varchar](100) NOT NULL,
	[Planned_Sales] [numeric](25, 12) NOT NULL,
	CONSTRAINT PK_CategoryWiseMonthlySalesPlan PRIMARY KEY ([Year], [Month], [Category])
) ON [PRIMARY]

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'AppPayModeMapping')
CREATE TABLE [dbo].[AppPayModeMapping](
	[BillPayMode] [varchar](25) NULL,
	[DisplayPayMode] [varchar](25) NULL
) ON [PRIMARY]








