CREATE OR ALTER PROCEDURE [dbo].[RSP_STOCKVARIANCEREPORT]
	@WAREHOUSE  VARCHAR(100)='%',
	@DATE1  DATETIME,
	@MGROUP  VARCHAR(100) = '%',
	@ADJUSTMENTBATCH  VARCHAR(100),
	@OPT_FLAG  TINYINT = 1,		--Difference:1,Excess:2,Shortage:3,Equal:4,NotInCount:5,All:6,PhysicalOnly:7
	@DATE2  DATETIME = GETDATE,
	@CHK_BYBARCODE tinyint = 0,	--ByBarcode:1:0
	@OPT_STOCKCOUNTING TINYINT = 0		--StockCounting:0,PurchaseCounting:1
AS

IF @OPT_STOCKCOUNTING =0
BEGIN
	IF @CHK_BYBARCODE  =0 
		exec dbo.SP_STOCKVARIANCEREPORT @WARE =@WAREHOUSE ,
			@DATE =@DATE2 ,
			@MGROUP =@MGROUP,
			@BATCH =@ADJUSTMENTBATCH ,
			@FLAG =@OPT_FLAG,
			@DATE1 =@DATE2,
			@BYBARCODE =@CHK_BYBARCODE
	ELSE
		exec dbo.SP_STOCKVARIANCEREPORT_BARCODEWISE @WARE =@WAREHOUSE ,
			@DATE =@DATE2 ,
			@MGROUP =@MGROUP,
			@BATCH =@ADJUSTMENTBATCH ,
			@FLAG =@OPT_FLAG,
			@DATE1 =@DATE2,
			@BYBARCODE =@CHK_BYBARCODE
END
ELSE
BEGIN
	exec dbo.SP_STOCKVARIANCEREPORT_PURCHASECHECK @WARE =@WAREHOUSE ,
			@DATE =@DATE2 ,
			@MGROUP =@MGROUP,
			@BATCH =@ADJUSTMENTBATCH ,
			@FLAG =@OPT_FLAG,
			@DATE1 =@DATE2,
			@BYBARCODE =@CHK_BYBARCODE
END