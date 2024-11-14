CREATE OR ALTER   PROCEDURE [dbo].[NSP_STOCKVARIANCEREPORT]
--DECLARE 
	@WARE AS VARCHAR(100)='%',
	@DATE AS DATETIME,
	@MGROUP AS VARCHAR(100) = '%',
	@BATCH AS VARCHAR(100),
	@FLAG AS TINYINT = 1,
	@BYBARCODE VARCHAR(25) = 0,
	@IGNOREADJUSTMENT TINYINT = 0,
	@SUPCODE AS VARCHAR(25) = '%',
	@ITEMLIST AS VARCHAR(8000)='',
	@FYID VARCHAR(15),
    @DIVISION VARCHAR(3) = '%'
	
AS

--SELECT @BATCH = '%', @WARE = 'Main Warehouse'

SET NOCOUNT ON
IF OBJECT_ID('TEMPDB..#TMPMENUITEM') is not null DROP TABLE #TMPMENUITEM
IF OBJECT_ID('TEMPDB..#TMPITEM') is not null DROP TABLE #TMPITEM
IF OBJECT_ID('TEMPDB..#ITEMLIST') is not null DROP TABLE #ITEMLIST

DROP TABLE IF EXISTS #AdjustmentVouchers 

DROP TABLE IF EXISTS #AdjustmentWarehouses

CREATE TABLE #TMPMENUITEM(MCODE VARCHAR(50),MGROUP VARCHAR(100))
CREATE TABLE #TMPITEM(MCODE VARCHAR(50),MGROUP VARCHAR(100))

DECLARE @BATCHTYPE TINYINT
DECLARE @GRPATH AS VARCHAR(1000)

SELECT @BATCHTYPE=BATCHTYPE, @DATE = TRNDATE FROM ADJUSTMENTBATCH WHERE BATCHNAME=@BATCH
IF @BATCHTYPE=0
	BEGIN
		INSERT INTO #TMPITEM SELECT A.MCODE,A.MGROUP  FROM MENUITEM A WHERE A.[TYPE]='A' AND ISNULL(A.SUPCODE,'') LIKE @SUPCODE	
	END 
ELSE IF @BATCHTYPE=1	-- ITEM MAIN GROUP
	BEGIN
		INSERT INTO #TMPITEM SELECT A.MCODE,A.MGROUP  FROM MENUITEM A INNER JOIN ADJUSTMENTBATCH_DETAIL B ON A.MGROUP=B.MCODE WHERE B.BATCHNAME=@BATCH AND A.[TYPE]='A'  AND ISNULL(A.SUPCODE,'') LIKE @SUPCODE	
	END

ELSE IF @BATCHTYPE=2	-- ITEM SUB GROUP
	BEGIN
	DECLARE GRPCURSOR CURSOR FOR SELECT [PATH] FROM ADJUSTMENTBATCH_DETAIL A INNER JOIN MENUITEM B ON A.MCODE=B.MCODE WHERE A.BATCHNAME=@BATCH

	OPEN GRPCURSOR

	FETCH NEXT FROM GRPCURSOR INTO @GRPATH

	WHILE @@FETCH_STATUS=0
		BEGIN
			INSERT INTO #TMPITEM SELECT MCODE,MGROUP  FROM MENUITEM WHERE PATH LIKE @GRPATH + '%' AND [TYPE]='A'  AND ISNULL(SUPCODE,'') LIKE @SUPCODE
			FETCH NEXT FROM GRPCURSOR INTO @GRPATH
		END
		
	CLOSE GRPCURSOR

	DEALLOCATE GRPCURSOR
	END
ELSE IF @BATCHTYPE=3		-- ITEM CATEGORY
	BEGIN
		INSERT INTO #TMPITEM SELECT A.MCODE,A.MGROUP  FROM MENUITEM A INNER JOIN ADJUSTMENTBATCH_DETAIL B ON A.MCAT=B.MCAT WHERE B.BATCHNAME=@BATCH AND A.[TYPE]='A'  AND ISNULL(A.SUPCODE,'') LIKE @SUPCODE	
	END
--SELECT * FROM #TMPITEM

SELECT VCHRNO INTO #AdjustmentVouchers FROM INVMAIN WHERE VOUCHERTYPE = 'SA' AND BILLTO = @BATCH

SELECT DISTINCT WAREHOUSE INTO #AdjustmentWarehouses FROM
(
	SELECT DISTINCT WAREHOUSE FROM INVPROD P JOIN INVMAIN M ON P.VCHRNO = M.VCHRNO WHERE M.VOUCHERTYPE = 'SA' AND M.BILLTO = @BATCH
	UNION 
	SELECT @WARE
) A


IF @ITEMLIST!=''
	BEGIN
		SELECT * INTO #ITEMLIST FROM DBO.Split(@ITEMLIST,',')
		INSERT INTO #TMPMENUITEM SELECT A.* FROM #TMPITEM A INNER JOIN #ITEMLIST B ON A.MCODE=B.ITEMS 
	END
ELSE
	BEGIN
		INSERT INTO #TMPMENUITEM SELECT * FROM #TMPITEM
	END

	IF OBJECT_ID('TEMPDB..#STOCKDATA') is not null drop table #STOCKDATA	
	SELECT A.MCODE,CASE WHEN @BYBARCODE = 1 THEN A.BC ELSE '' END BC,SUM(REALQTY_IN)-SUM(REALQTY) CSTOCK
	INTO #STOCKDATA
	FROM RMD_TRNPROD A INNER JOIN RMD_TRNMAIN B ON A.VCHRNO = B.VCHRNO AND A.DIVISION = B.DIVISION 
	INNER JOIN #TMPMENUITEM X ON A.MCODE = X.MCODE
	JOIN #AdjustmentWarehouses W ON A.WAREHOUSE = W.WAREHOUSE
	LEFT JOIN #AdjustmentVouchers AV ON B.VCHRNO = AV.VCHRNO
	WHERE AV.VCHRNO IS NULL AND X.MGROUP LIKE @MGROUP AND B.TRNDATE<=@DATE AND B.PhiscalID = @FYID AND B.DIVISION LIKE @DIVISION
	AND ((@IGNOREADJUSTMENT = 0 AND ISNULL(B.REFBILL,'') <> 'X') OR (@IGNOREADJUSTMENT = 1 AND ISNULL(B.REFBILL,'') <> @BATCH))
	GROUP BY A.MCODE,CASE WHEN @BYBARCODE = 1 THEN A.BC ELSE '' END HAVING SUM(REALQTY_IN)-SUM(REALQTY)<>0

	--SELECT * FROM #STOCKDATA

	IF OBJECT_ID('TEMPDB..#COUNTDATA') is not null drop table #COUNTDATA
	SELECT A.MCODE, CASE WHEN @BYBARCODE = 1 THEN A.BCODE ELSE '' END BC,SUM(QTY) AS PSTOCK 
	INTO #COUNTDATA
	FROM MANUALSTOCKS A INNER JOIN #TMPMENUITEM X ON A.MCODE = X.MCODE
	WHERE A.BATCH LIKE @BATCH AND A.WAREHOUSE LIKE @WARE AND X.MGROUP LIKE @MGROUP  AND A.PhiscalID = @FYID
	GROUP BY A.MCODE,CASE WHEN @BYBARCODE = 1 THEN A.BCODE ELSE '' END

	--SELECT * FROM #COUNTDATA
	
	IF OBJECT_ID('TEMPDB..#COUNTDATA_ALL') is not null drop table #COUNTDATA_ALL
	SELECT A.MCODE, CASE WHEN @BYBARCODE = 1 THEN A.BCODE ELSE '' END BC,SUM(QTY) AS PSTOCK 
	INTO #COUNTDATA_ALL
	FROM MANUALSTOCKS A LEFT JOIN MENUITEM X ON A.MCODE = X.MCODE
	WHERE A.BATCH LIKE @BATCH AND A.TRNDATE = @DATE AND A.WAREHOUSE LIKE @WARE AND ISNULL(X.MGROUP,'') LIKE @MGROUP  AND A.PhiscalID = @FYID
	GROUP BY A.MCODE,CASE WHEN @BYBARCODE = 1 THEN A.BCODE ELSE '' END

IF @FLAG < 5		 -- VARIANCE REPORT
	
	SELECT A.MENUCODE, A.DESCA, A.BASEUNIT,B.BC, CONVERT(numeric(18,2), A.PRATE_A) PRATE, CONVERT(numeric(18,2),A.RATE_A) SRATE, B.PSTOCK
	, CONVERT(numeric(18,2),B.PSTOCK * A.PRATE_A) AS PSTOCKVALUE,
	C.CSTOCK
	, CONVERT(numeric(18,2),C.CSTOCK * A.PRATE_A) AS CSTOCKVALUE,  	
	CASE WHEN (B.PSTOCK - ISNULL(C.CSTOCK,0) > 0) THEN B.PSTOCK - ISNULL(C.CSTOCK,0) ELSE NULL END AS  EXCESSSTOCK,
	CONVERT(numeric(18,2),CASE WHEN (B.PSTOCK - ISNULL(C.CSTOCK,0) > 0) THEN (B.PSTOCK - ISNULL(C.CSTOCK,0)) * A.PRATE_A ELSE NULL END) AS  EXCESSSTOCKVALUE,
	CASE WHEN (B.PSTOCK - ISNULL(C.CSTOCK,0) < 0) THEN ISNULL(C.CSTOCK,0) - B.PSTOCK ELSE NULL END AS  SHORTAGESTOCK,
	CONVERT(numeric(18,2),CASE WHEN (B.PSTOCK - ISNULL(C.CSTOCK,0) < 0) THEN (ISNULL(C.CSTOCK,0) - B.PSTOCK) * A.PRATE_A ELSE NULL END) AS  SHORTAGESTOCKVALUE,
	A.MCODE
	FROM #COUNTDATA B INNER JOIN  #STOCKDATA C ON B.MCODE = C.MCODE AND B.BC = C.BC INNER JOIN MENUITEM A ON B.MCODE = A.MCODE
	WHERE @FLAG = 0 OR ((@FLAG =1 AND ISNULL(B.PSTOCK,0) <> ISNULL(C.CSTOCK,0)) OR (@FLAG =2 AND ISNULL(B.PSTOCK,0) - ISNULL(C.CSTOCK,0) > 0) 
	OR (@FLAG =3 AND ISNULL(B.PSTOCK,0) - ISNULL(C.CSTOCK,0) < 0) OR (@FLAG =4 AND ISNULL(B.PSTOCK,0) - ISNULL(C.CSTOCK,0) = 0))
	ORDER BY A.DESCA,A.MENUCODE,B.BC
	
ELSE IF @FLAG = 5		-- STOCK NOT COMES IN PHYSICALL COUNTING

	SELECT A.MENUCODE, A.DESCA,A.BASEUNIT,C.BC, CONVERT(numeric(18,2), A.PRATE_A) PRATE, CONVERT(numeric(18,2),A.RATE_A) SRATE, 0 PSTOCK, 0 PSTOCKVALUE,
	C.CSTOCK,C.CSTOCK * A.PRATE_A AS CSTOCKVALUE,0 EXCESSSTOCK,0 EXCESSSTOCKVALUE,
	ISNULL(C.CSTOCK,0) SHORTAGESTOCK, ISNULL(C.CSTOCK,0) * A.PRATE_A SHORTAGESTOCKVALUE, A.MCODE
	FROM #STOCKDATA C LEFT JOIN #COUNTDATA B ON B.MCODE = C.MCODE AND C.BC = B.BC INNER JOIN MENUITEM A ON C.MCODE = A.MCODE
	WHERE B.MCODE IS NULL AND A.PTYPE < 10 ORDER BY A.DESCA,A.MENUCODE,B.BC
	
ELSE IF @FLAG = 6		-- STOCK COME IN COUNTING BUT NOT IN STOCK
	SELECT A.MENUCODE, A.DESCA,A.BASEUNIT, B.BC, CONVERT(numeric(18,2), A.PRATE_A) PRATE, CONVERT(numeric(18,2),A.RATE_A) SRATE, B.PSTOCK, B.PSTOCK * A.PRATE_A PSTOCKVALUE,
	0 CSTOCK,0 CSTOCKVALUE,B.PSTOCK EXCESSSTOCK,B.PSTOCK * A.PRATE_A EXCESSSTOCKVALUE,
	0 SHORTAGESTOCK, 0 SHORTAGESTOCKVALUE, A.MCODE
	FROM #COUNTDATA B LEFT JOIN #STOCKDATA C ON B.MCODE = C.MCODE AND B.BC = C.BC INNER JOIN MENUITEM A ON B.MCODE = A.MCODE
	WHERE C.MCODE IS NULL AND A.PTYPE < 10 AND B.PSTOCK<>0 ORDER BY A.DESCA,A.MENUCODE,B.BC

ELSE IF @FLAG = 8		-- STOCK COME IN COUNTING BUT NOT IN SCOPE
	SELECT A.MENUCODE, A.DESCA,A.BASEUNIT, B.BC, CONVERT(numeric(18,2), A.PRATE_A) PRATE, CONVERT(numeric(18,2),A.RATE_A) SRATE, B.PSTOCK, B.PSTOCK * A.PRATE_A PSTOCKVALUE,
	0 CSTOCK,0 CSTOCKVALUE,B.PSTOCK EXCESSSTOCK,B.PSTOCK * A.PRATE_A EXCESSSTOCKVALUE,
	0 SHORTAGESTOCK, 0 SHORTAGESTOCKVALUE, A.MCODE
	FROM #COUNTDATA_ALL B LEFT JOIN #STOCKDATA C ON B.MCODE = C.MCODE AND B.BC = C.BC INNER JOIN MENUITEM A ON B.MCODE = A.MCODE
	WHERE C.MCODE IS NULL AND A.PTYPE < 10 AND B.MCODE NOT IN (SELECT MCODE FROM #TMPMENUITEM) ORDER BY A.DESCA,A.MENUCODE,B.BC
	
	
ELSE IF @FLAG = 7	-- PHYSICAL STOCK ONLY	

	SELECT C.MENUCODE, C.DESCA, C.BASEUNIT, A.BCODE, CONVERT(numeric(18,2), C.PRATE_A) PRATE, CONVERT(numeric(18,2),C.RATE_A) SRATE,SUM(QTY) AS PSTOCK,
	SUM(QTY) * C.PRATE_A AS PSTOCKVALUE,A.MCODE FROM MANUALSTOCKS A, MENUITEM C WHERE A.MCODE = C.MCODE 
	AND A.BATCH LIKE @BATCH AND (A.TRNDATE >= @DATE AND A.TRNDATE <= @DATE) AND WAREHOUSE LIKE @WARE AND C.MGROUP LIKE @MGROUP  AND A.PhiscalID = @FYID AND C.PTYPE < 10
	GROUP BY A.MCODE, C.DESCA, C.BASEUNIT, C.MENUCODE,C.PRATE_A, C.RATE_A,FCODE, ECODE,A.BCODE


	IF OBJECT_ID('TEMPDB..#STOCKDATA') is not null drop table #STOCKDATA
	IF OBJECT_ID('TEMPDB..#COUNTDATA') is not null drop table #COUNTDATA

set nocount OFF

