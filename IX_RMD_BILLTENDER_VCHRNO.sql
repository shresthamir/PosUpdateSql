IF NOT EXISTS (SELECT * FROM SYS.INDEXES WHERE NAME = 'IX_RMD_BILLTENDER_VCHRNO')
CREATE NONCLUSTERED INDEX [IX_ABBMAIN_VOUCHERTYPE] ON [dbo].[ABBMAIN]
(
	VOUCHERTYPE ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]


USE [POSDB]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_RMD_BILLTENDER_VCHRNO]    Script Date: 10/25/2019 5:05:24 PM ******/
CREATE NONCLUSTERED INDEX [IX_RMD_BILLTENDER_VCHRNO] ON [dbo].[RMD_BILLTENDER]
(
	[VCHRNO] ASC,
	[DIVISION] ASC,
	[PHISCALID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO



