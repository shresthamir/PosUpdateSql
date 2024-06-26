CREATE OR ALTER PROCEDURE [dbo].[RSP_STOCKREPORT_SUMMARY] 
--DBCC DROPCLEANBUFFERS
--DBCC FREEPROCCACHE
--DECLARE
	@DATE1 DATETIME,
	@DATE2 DATETIME,
	@WAREHOUSE VARCHAR(100) ='%',
	@MENUCAT VARCHAR(100) ='%',
	@SUPPLIER_ACID VARCHAR(20)='%',
	@MGROUP VARCHAR(20) = '%',
	@PTYPE INT='100',
	@PATH NVARCHAR(4000)='%',
	@CHK_BarcodeWise TINYINT =0,                        --CHK_BarcodeWise:1:0
	@OPT_WISE VARCHAR(50) = 'MGroup',            			--Mgroup:Mgroup,Item:Item,MCat:MCat
	@MCODE varchar(25) = '%',
	@barcode VARCHAR(25) = '%',
	@DIVISION VARCHAR(3)= '%',
	@OPT_RepMode tinyint = 0,					--All:0,NonZero:1,NegativeOnly:2,ZeroOnly:3
	@OPT_TREE tinyint = 0,                                          --NonTree:0,Tree:1
	@OPT_FIFO TINYINT = 1,                      ----FIFO:1,LatestMRP:0
	@GROUP VARCHAR(25)='MI',
	@DOVALUATION TINYINT = 1,
	@CHK_GRNWise TINYINT = 0,                     --CHK_GRNWise:1:0   
	@FYID VARCHAR(20) = '%',
	@CHK_WarehouseDetail TINYINT = 0					  --CHK_WarehouseDetail:1:0	
AS
IF @OPT_FIFO = 1 
	SET @DOVALUATION = 1

--SET @DATE1 = '2022-07-16'; SET @DATE2 ='2023-07-15';
--SET @FYID = '79/80'; --SET @MCODE = 'M5374'
set nocount on

DECLARE @SHOWBARCODEDETAIL TINYINT
DECLARE @IGNOREMINUSTK TINYINT
DECLARE @BCWISERATE TINYINT
SELECT @SHOWBARCODEDETAIL = CONVERT(TINYINT, EnableBarcodeDetails) | ISNULL(HASVEHICLESALE,0),@IGNOREMINUSTK = IGNOREMINUSSTKINSVALUATION,@BCWISERATE = ISNULL(BarcodeWisePrice,0) FROM SETTING
if @OPT_FIFO = 0
	set @DOVALUATION = 0

--Drop Temp Tables
IF OBJECT_ID('TEMPDB..#tblWarehouse') is not NULL drop table #tblWarehouse
IF OBJECT_ID('TEMPDB..#RMD_TRNPROD') IS NOT NULL DROP TABLE #RMD_TRNPROD
IF OBJECT_ID('TEMPDB..#STOCK_SUMMARY') IS NOT NULL DROP TABLE #STOCK_SUMMARY
IF OBJECT_ID('TEMPDB..#STOCK_WithItemDetail') IS NOT NULL DROP TABLE #STOCK_WithItemDetail
IF OBJECT_ID('TEMPDB..#RESULT') IS NOT NULL DROP TABLE #RESULT
IF OBJECT_ID('TEMPDB..#DIV_WAREHOUSE') IS NOT NULL DROP TABLE #DIV_WAREHOUSE
IF OBJECT_ID('TEMPDB..#COLS') is not NULL drop table #COLS

--Create Temp Tables
CREATE TABLE #tblWarehouse (item varchar(100) COLLATE DATABASE_DEFAULT)
CREATE TABLE #COLS(RN INT NOT NULL, SELECTION_COLS VARCHAR(MAX) NOT NULL, AGG_COLS VARCHAR(MAX) NOT NULL)

--GETTING WAREHOUSE LIST
INSERT INTO #tblWarehouse SELECT ITEMS FROM DBO.Split(@WAREHOUSE ,',')

--STOCK VALUATION
-------------------
IF @DOVALUATION = 1
BEGIN
	DELETE FROM COSTING		
	EXEC RSP_STOCKVALUATION_FIFO @DATE = @DATE2,@PATH = '%',@FYID = @FYID,@DETAIL = 100,@ITEM = @MCODE
END


SELECT 'OP100' VCHRNO,A.DIVISION, A.MCODE,SUM(REALQTY) REALQTY,
SUM(REALQTY_IN) REALQTY_IN,WAREHOUSE,IIF(@CHK_BarcodeWise = 1, A.BC,'') BC, A.VoucherType INTO #RMD_TRNPROD FROM RMD_TRNPROD A 
INNER JOIN RMD_TRNMAIN B ON A.VCHRNO=B.VCHRNO AND A.DIVISION =B.DIVISION AND A.PhiscalID=B.PhiscalID 
WHERE ISNULL(A.PHISCALID,'') = @FYID AND (B.TRNDATE < @DATE1 OR A.VCHRNO LIKE 'OP%') AND B.DIVISION LIKE @DIVISION AND
(A.WAREHOUSE LIKE @WAREHOUSE OR A.WAREHOUSE IN (SELECT ITEM FROM #tblWarehouse)) AND ISNULL(A.MCODE,'') LIKE @MCODE 
GROUP BY A.DIVISION,A.MCODE,A.WAREHOUSE, IIF(@CHK_BarcodeWise = 1, A.BC,''), A.VoucherType

UNION ALL

SELECT A.VCHRNO VCHRNO,A.DIVISION,A.MCODE,REALQTY,
REALQTY_IN,WAREHOUSE,IIF(@CHK_BarcodeWise = 1, A.BC,'') BC, A.VoucherType FROM RMD_TRNPROD A 
INNER JOIN RMD_TRNMAIN B ON A.VCHRNO=B.VCHRNO AND A.DIVISION =B.DIVISION AND A.PhiscalID=B.PhiscalID 
WHERE ISNULL(A.PHISCALID,'') = @FYID AND B.TRNDATE BETWEEN @DATE1 AND @DATE2 AND A.VCHRNO NOT LIKE 'OP%' AND B.DIVISION LIKE @DIVISION
AND (A.WAREHOUSE LIKE @WAREHOUSE OR A.WAREHOUSE IN (SELECT ITEM FROM #tblWarehouse)) AND ISNULL(A.MCODE,'') LIKE @MCODE 


--GETTING ITEM WISE STOCK BALANCE RECORD WITH STOCK VALUE
---------------------------------------------------------
SELECT * INTO #STOCK_SUMMARY FROM
(
	SELECT A.MCODE,A.DIVISION, A.WAREHOUSE, A.OPQTY,A.INQTY,A.OUTQTY,A.STOCKBALANCE,
	BARCODE = A.BC,
	PRATE = CASE WHEN @IGNOREMINUSTK = 1 AND A.STOCKBALANCE<0 THEN 0 ELSE B.PRATE END, 
	STOCKVALUE= (CASE WHEN @IGNOREMINUSTK = 1 AND A.STOCKBALANCE<0 THEN 0 ELSE B.PRATE END) * A.STOCKBALANCE
	FROM 
	(
		SELECT MCODE, DIVISION, WAREHOUSE,
		OPQTY = SUM(IIF(VoucherType IN ('OP'), REALQTY_IN-RealQty, 0)),
		INQTY = SUM(IIF(REALQTY_IN > 0, REALQTY_IN, 0)) ,
		OUTQTY= SUM(IIF(REALQTY_IN > 0, 0, RealQty)),
		STOCKBALANCE=SUM(REALQTY_IN)-SUM(REALQTY), BC
		FROM #RMD_TRNPROD A GROUP BY A.MCODE, A.BC, A.DIVISION, A.WAREHOUSE
	) A 
	LEFT JOIN 
	(
		SELECT A.MCODE,CASE WHEN @OPT_FIFO = 0 THEN ISNULL(CASE WHEN ISNULL(A.CRATE,0) = 0 THEN A.PRATE_A ELSE ISNULL(A.CRATE,0) END,0) ELSE ISNULL(X.RATE,0) END PRATE FROM
		MENUITEM A LEFT JOIN COSTING X ON A.MCODE = X.MCODE
	) B ON A.MCODE = B.MCODE
)A WHERE ((@OPT_RepMode = 1 AND STOCKBALANCE <> 0) OR (@OPT_RepMode = 2 AND STOCKBALANCE < 0) OR (@OPT_RepMode = 3 AND STOCKBALANCE = 0) OR  (@OPT_RepMode = 0 AND STOCKBALANCE < 1000000000)) 

--PREPARING RECORD TO SHOW REPORT AS PER REPORT OPTION
--------------------------------------------------------
SELECT * INTO #STOCK_WithItemDetail FROM 
(
	SELECT  CASE @OPT_WISE WHEN 'ITEM' THEN B.MENUCODE WHEN 'ITEMCATEGORY' THEN '' ELSE ISNULL(C.MENUCODE,'') END ITEMCODE,
	CASE @OPT_WISE WHEN 'ITEM' THEN B.DESCA WHEN 'ITEMCATEGORY' THEN ISNULL(B.MCAT,'N/A') ELSE ISNULL(C.DESCA,'') END DESCA,
	CASE @OPT_WISE WHEN 'ITEM' THEN CASE WHEN @CHK_BarcodeWise=0 THEN ISNULL(B.BARCODE,B.MENUCODE) ELSE A.BARCODE END ELSE '' END AS BARCODE,
	CASE @OPT_WISE WHEN 'ITEM' THEN B.BASEUNIT ELSE '' END BASEUNIT, 
	A.DIVISION, WAREHOUSE,
	OPQTY,INQTY,OUTQTY,STOCKBALANCE,
	CASE @OPT_WISE WHEN 'ITEM' THEN CONVERT(NUMERIC(18,4), A.PRATE) ELSE 0 END PRATE,
	STOCKVALUE,
	CASE @OPT_WISE WHEN 'ITEM' THEN CONVERT(NUMERIC(18,4), B.RATE_A) ELSE 0 END SRATE,
	CASE @OPT_WISE WHEN 'ITEM' THEN D.ACNAME ELSE '' END SUPPLIER,
	CASE @OPT_WISE WHEN 'ITEM' THEN A.MCODE WHEN 'ITEMCATEGORY' THEN ISNULL(B.MCAT,'N/A') ELSE ISNULL(B.MGROUP,'') END MCODE
	FROM #STOCK_SUMMARY A INNER JOIN MENUITEM B ON A.MCODE= B.MCODE 
	LEFT JOIN MENUITEM C ON B.MGROUP = C.MCODE 
	LEFT JOIN RMD_ACLIST D ON ISNULL(B.SUPCODE,'') = D.ACID
	WHERE ISNULL(B.MCAT,'') LIKE @MENUCAT AND ISNULL(B.MGROUP,'') LIKE @MGROUP AND ISNULL(B.SUPCODE,'') LIKE @SUPPLIER_ACID AND
	((@PATH='%' AND ISNULL(B.PATH,'') LIKE @PATH) OR (@PATH <> '%' 
	AND B.PARENT IN (SELECT MCODE FROM DBO.TreeExpand_function(@PATH,'PATH','1'))))
	AND ((@PTYPE=100 AND ISNULL(B.PTYPE,0)<10) OR (@PTYPE <> 100 AND ISNULL(B.PTYPE,0) = @PTYPE))
)A 
--SELECT * FROM #STOCK_WithItemDetail ORDER BY DESCA

SELECT IH.[Main Group], IH.[Main Category], IH.[Sub Category], IH.[Super Category], ITEMCODE, A.DESCA, BARCODE, DIVISION, WAREHOUSE, BASEUNIT,
SUM(OPQTY) OPQTY, SUM(INQTY) INQTY, SUM(OUTQTY) OUTQTY,
SUM(STOCKBALANCE) STOCKBALANCE, PRATE,SUM(STOCKVALUE)STOCKVALUE,A.SRATE,A.SUPPLIER,A.MCODE
INTO #RESULT
FROM #STOCK_WithItemDetail A 
LEFT JOIN vwItemHeirarchy IH ON A.MCODE = IH.MCODE
GROUP BY IH.[Main Group], IH.[Main Category], IH.[Sub Category], IH.[Super Category], A.ITEMCODE,A.DESCA,A.BARCODE,A.BASEUNIT,A.PRATE,A.SRATE,A.SUPPLIER,A.MCODE, A.DIVISION, A.WAREHOUSE
ORDER BY A.DESCA


SELECT DISTINCT DIVISION, WAREHOUSE INTO #DIV_WAREHOUSE FROM RMD_TRNPROD


DECLARE @HasVariant BIT = @SHOWBARCODEDETAIL & @CHK_BarcodeWise
DECLARE @query  AS VARCHAR(MAX),@fixedColumns AS VARCHAR(MAX), @columns  AS NVARCHAR(MAX), @agg_columns AS VARCHAR(MAX);



IF @CHK_WarehouseDetail = 1
BEGIN
	INSERT INTO #COLS
	SELECT ROW_NUMBER() OVER (ORDER BY DIVISION,  WAREHOUSE, FLG) RN,
	CONCAT('IIF(DIVISION = ''', DIVISION, ''' AND WAREHOUSE = ''', WAREHOUSE, ''', ', valColum, ', 0) ', colName) SELECTION_COLS, 
	CONCAT('SUM(', colName, ') ', colName) AGG_COLS FROM
	(	SELECT DIVISION, WAREHOUSE, 'OpQty' valColum,  QUOTENAME(CONCAT(DIVISION, '_', WAREHOUSE, '_OP')) colName, 1 FLG FROM #DIV_WAREHOUSE
		UNION 
		SELECT DIVISION, WAREHOUSE, 'InQty', QUOTENAME(CONCAT(DIVISION, '_', WAREHOUSE, '_IN')), 2 FROM #DIV_WAREHOUSE
		UNION 
		SELECT DIVISION, WAREHOUSE, 'OutQty', QUOTENAME(CONCAT(DIVISION, '_', WAREHOUSE, '_OUT')), 3 FROM #DIV_WAREHOUSE
		UNION 
		SELECT DIVISION, WAREHOUSE, 'StockBalance', QUOTENAME(CONCAT(DIVISION, '_', WAREHOUSE, '_BAL')), 4 FLG FROM #DIV_WAREHOUSE	
		UNION 
		SELECT DIVISION, WAREHOUSE, 'StockValue', QUOTENAME(CONCAT(DIVISION, '_', WAREHOUSE, '_VAL')), 5 FLG FROM #DIV_WAREHOUSE	
	) X
END
ELSE
	INSERT INTO #COLS
	SELECT ROW_NUMBER() OVER (ORDER BY DIVISION, FLG) RN,
	CONCAT('IIF(DIVISION = ''', DIVISION, ''',', valColum, ', 0) ', colName )SELECTION_COLS, 
	CONCAT('SUM(', colName, ') ', colName) AGG_COLS FROM
	(
		SELECT DIVISION, 'OpQty' valColum, QUOTENAME(CONCAT(DIVISION, '_OP')) colName, 1 FLG FROM #DIV_WAREHOUSE
		UNION 
		SELECT DIVISION, 'InQty', QUOTENAME(CONCAT(DIVISION, '_IN')), 2 FROM #DIV_WAREHOUSE
		UNION 
		SELECT DIVISION, 'OutQty', QUOTENAME(CONCAT(DIVISION, '_OUT')), 3 FROM #DIV_WAREHOUSE
		UNION 
		SELECT DIVISION, 'StockBalance', QUOTENAME(CONCAT(DIVISION, '_BAL')), 4 FROM #DIV_WAREHOUSE	
		UNION 
		SELECT DIVISION, 'StockValue', QUOTENAME(CONCAT(DIVISION, '_VAL')), 5 FROM #DIV_WAREHOUSE	
	) X

SELECT @columns = STRING_AGG(SELECTION_COLS, ',' + CHAR(10)), @agg_columns = STRING_AGG(AGG_COLS,  ',' + CHAR(10)) FROM
(
	SELECT * FROM #COLS 
) A

--print @columns

SET @fixedColumns = 'A.[Main Group], A.[Main Category], A.[Sub Category], A.[Super Category], A.ITEMCODE, A.DESCA, A.BASEUNIT,A.PRATE, A.SRATE, A.SUPPLIER, A.MCODE, A.BARCODE '
--PRINT @colOp
SET @query = '
	SELECT ' + @fixedColumns + IIF(@HasVariant = 1,', A.SIZE, A.COLOR ','') + ',' + CHAR(10) + @agg_columns + ' FROM
	(
		SELECT ' + @fixedColumns + IIF(@HasVariant = 1,', BD.SIZE, BD.COLOR ','') + ',' + CHAR(10) + @columns + ' 
		FROM #RESULT A ' 
		+ IIF(@HasVariant = 1, 'LEFT JOIN BARCODE_DETAIL BD ON A.MCODE = BD.MCODE AND A.BARCODE = BD.BARCODE','') + '
	) A
	GROUP BY ' + @fixedColumns + IIF(@HasVariant = 1,', A.SIZE, A.COLOR ','') + '
	ORDER BY A.DESCA
'
PRINT @QUERY
EXECUTE(@QUERY)

IF OBJECT_ID('TEMPDB..#tblWarehouse') is not NULL drop table #tblWarehouse
IF OBJECT_ID('TEMPDB..#RMD_TRNPROD') IS NOT NULL DROP TABLE #RMD_TRNPROD
IF OBJECT_ID('TEMPDB..#STOCK_SUMMARY') IS NOT NULL DROP TABLE #STOCK_SUMMARY
IF OBJECT_ID('TEMPDB..##STOCK_WithItemDetail') IS NOT NULL DROP TABLE #STOCK_WithItemDetail
IF OBJECT_ID('TEMPDB..#RESULT') IS NOT NULL DROP TABLE #RESULT
IF OBJECT_ID('TEMPDB..#DIV_WAREHOUSE') IS NOT NULL DROP TABLE #DIV_WAREHOUSE
IF OBJECT_ID('TEMPDB..#COLS') is not NULL drop table #COLS