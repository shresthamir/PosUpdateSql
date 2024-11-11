CREATE OR ALTER PROCEDURE [dbo].[RSP_VATSALESREGISTER]
@DATE1 DATETIME,
@DATE2 DATETIME,
@DIVISION VARCHAR(25) = '%',
@CHK_IncludeTaxInvoice VARCHAR(2) = '',              --IncludeTaxInvoice:TI:1
@CHK_INCLUDEABBSALES VARCHAR(2) = '',              --IncludeAbbSales:SI:1
@CHK_INCLUDECREDITNOTE VARCHAR(2) = '',          --IncludeCreditNotes:CN:0
@OPT_RepMode TINYINT = 0,                             --Details:0,Summary:1
@CHK_OLDFORMAT TINYINT = 0                       --OldFomrat:1:0
AS
DECLARE @V1 VARCHAR(2) = '', @V2 VARCHAR(2) = ''
IF @CHK_OLDFORMAT = 0
    EXEC NSP_VATSALESREGISTER_NEWFORMAT
	@DATE1 = @DATE1,
	@DATE2 = @DATE2,
	@DIV = @DIVISION,
	@V1 = @CHK_INCLUDEABBSALES, 
	@V2 = @CHK_INCLUDECREDITNOTE,
	@V3 = @CHK_IncludeTaxInvoice,
	@REPMODE = @OPT_RepMode
ELSE 
    EXEC NSP_VATSALESREGISTER
	@DATE1 = @DATE1,
	@DATE2 = @DATE2,
	@DIV = @DIVISION,
	@V1 = @CHK_INCLUDEABBSALES, 
	@V2 = @CHK_INCLUDECREDITNOTE,
	@V3 = @CHK_IncludeTaxInvoice,
	@REPMODE = @OPT_RepMode