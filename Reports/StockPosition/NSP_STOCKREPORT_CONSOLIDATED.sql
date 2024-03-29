CREATE OR ALTER PROCEDURE [dbo].[NSP_STOCKREPORT_CONSOLIDATED] 
--DBCC DROPCLEANBUFFERS
--DBCC FREEPROCCACHE
--DECLARE
	@DATE1 DATETIME,
	@DATE2 DATETIME,
	@WAREHOUSE VARCHAR(100) ='%',
	@CATEGORY VARCHAR(100) ='%',
	@SUPPLIER VARCHAR(25)='%',
	@ITEMGROUP VARCHAR(25) = '%',
	@PTYPE INT='100',
	@PATH NVARCHAR(4000)='%',
	@BYBARCODE TINYINT = 0,
	@WISE VARCHAR(50) = 'ITEM', 
	@ItemCode varchar(25) = '%',
	@barcode VARCHAR(25) = '%',
	@DIVISION VARCHAR(3)= '%',
	@RepMode tinyint = 0,
	@TreeFormat tinyint = 0,
	@SHOWVALUATIONRATE TINYINT = 0,
	@GROUP VARCHAR(25)='MI',
	@DOVALUATION TINYINT = 0,
	@GRNWise TINYINT = 0,
	@FYID VARCHAR(10) = '77/78'
AS

--SET @DATE1 = '2020-07-16'; SET @DATE2 ='2021-07-15';
--SET @FYID = '77/78'
set nocount on

DECLARE @SHOWBARCODEDETAIL TINYINT
DECLARE @IGNOREMINUSTK TINYINT
DECLARE @BCWISERATE TINYINT
SELECT @SHOWBARCODEDETAIL = CONVERT(TINYINT, EnableBarcodeDetails) | ISNULL(HASVEHICLESALE,0),@IGNOREMINUSTK = IGNOREMINUSSTKINSVALUATION,@BCWISERATE = ISNULL(BarcodeWisePrice,0) FROM SETTING
if @SHOWVALUATIONRATE = 0
	set @DOVALUATION = 0

--GETTING WAREHOUSE LIST
-------------------------
IF OBJECT_ID('TEMPDB..#tblWarehouse') is not NULL drop table #tblWarehouse

CREATE TABLE #tblWarehouse (item varchar(100) COLLATE DATABASE_DEFAULT)
INSERT INTO #tblWarehouse SELECT ITEMS FROM DBO.Split(@WAREHOUSE ,',')

--STOCK VALUATION
-------------------
IF @DOVALUATION = 1
BEGIN
	DELETE FROM COSTING		
	--EXEC NSP_STOCKVALUATIONREPORT @DATE = @DATE2,@PATH = '%',@PHISCALID = @FYID,@DETAIL = 100,@ITEM = @ItemCode,@DOVALUATION = @DOVALUATION,@FIFO = 'F'	
	EXEC RSP_STOCKVALUATION_FIFO @DATE = @DATE2,@PATH = '%',@FYID = @FYID,@DETAIL = 100,@ITEM = @ItemCode
END

IF OBJECT_ID('TEMPDB..#RMD_TRNPROD') IS NOT NULL DROP TABLE #RMD_TRNPROD
--IF OBJECT_ID('TEMPDB..#DATA') IS NOT NULL DROP TABLE #DATA

SELECT 'OP100' VCHRNO,A.DIVISION,A.MCODE,SUM(REALQTY) REALQTY,
SUM(REALQTY_IN) REALQTY_IN,WAREHOUSE,A.BC INTO #RMD_TRNPROD FROM RMD_TRNPROD A 
INNER JOIN RMD_TRNMAIN B ON A.VCHRNO=B.VCHRNO AND A.DIVISION =B.DIVISION AND A.PhiscalID=B.PhiscalID 
WHERE ISNULL(A.PHISCALID,'') = @FYID AND (B.TRNDATE < @DATE1 OR A.VCHRNO LIKE 'OP%') AND B.DIVISION LIKE @DIVISION AND
(A.WAREHOUSE LIKE @WAREHOUSE OR A.WAREHOUSE IN (SELECT ITEM FROM #tblWarehouse)) AND ISNULL(A.MCODE,'') LIKE @ITEMCODE 
GROUP BY A.DIVISION,A.MCODE,A.WAREHOUSE,A.BC

UNION ALL

SELECT A.VCHRNO VCHRNO,A.DIVISION,A.MCODE,REALQTY,
REALQTY_IN,WAREHOUSE,A.BC FROM RMD_TRNPROD A 
INNER JOIN RMD_TRNMAIN B ON A.VCHRNO=B.VCHRNO AND A.DIVISION =B.DIVISION AND A.PhiscalID=B.PhiscalID 
WHERE ISNULL(A.PHISCALID,'') = @FYID AND B.TRNDATE BETWEEN @DATE1 AND @DATE2 AND A.VCHRNO NOT LIKE 'OP%' AND B.DIVISION LIKE @DIVISION
AND (A.WAREHOUSE LIKE @WAREHOUSE OR A.WAREHOUSE IN (SELECT ITEM FROM #tblWarehouse)) AND ISNULL(A.MCODE,'') LIKE @ITEMCODE 

--GETTING ITEM WISE STOCK BALANCE RECORD WITH STOCK VALUE
---------------------------------------------------------
IF OBJECT_ID('TEMPDB..#RMD_TRNPROD1') IS NOT NULL DROP TABLE #RMD_TRNPROD1

SELECT * INTO #RMD_TRNPROD1 FROM
(
	SELECT A.MCODE,A.DIVISION,A.OPQTY,A.PQTY,A.TRANSFERIN,A.SALESQTY,A.TRANSFEROUT,A.STOCKADJUSTMENT,A.SETTLEMENT,A.STOCKBALANCE,
	--A.MCAT,A.DESCA,A.MENUCODE,A.MGROUP,A.MGROUPNAME,A.MGROUPCODE,A.SUPPLIER,A.BASEUNIT,A.SRATE,
	--BARCODE = CASE WHEN @BYBARCODE=0 THEN ISNULL(A.BARCODE,A.MENUCODE) ELSE CASE WHEN ISNULL(A.BC,'') = '' THEN A.BARCODE ELSE A.BC END END,
	BARCODE = A.BC,
	PRATE = CASE WHEN @IGNOREMINUSTK = 1 AND A.STOCKBALANCE<0 THEN 0 ELSE B.PRATE END, 
	STOCKVALUE= (CASE WHEN @IGNOREMINUSTK = 1 AND A.STOCKBALANCE<0 THEN 0 ELSE B.PRATE END) * A.STOCKBALANCE
	FROM 
	(
		SELECT MCODE, DIVISION,
		OPQTY=SUM(CASE LEFT(VCHRNO,2) WHEN 'OP' THEN  REALQTY_IN-RealQty ELSE 0 END ),
		PQTY=SUM(CASE WHEN LEFT(VCHRNO,2) IN ('PI','PR','DN','GR') THEN REALQTY_IN-REALQTY ELSE 0 END) ,
		TRANSFERIN=SUM(CASE WHEN LEFT(VCHRNO,2) IN ('IS','TR','HV','SO','PK') THEN REALQTY_IN ELSE 0 END ), 
		SALESQTY=SUM(CASE WHEN LEFT(VCHRNO,2) IN ('SI','SR','TI','CN','RE','IV','IC','IR','NC','DL','DR') THEN REALQTY-REALQTY_in ELSE 0 END ),
		TRANSFEROUT=SUM(CASE WHEN LEFT(VCHRNO,2) IN ('IS','TO','HV','SO','PK') THEN REALQTY ELSE 0 END ), 
		STOCKADJUSTMENT=SUM(CASE LEFT(VCHRNO,2) WHEN 'SA' THEN REALQTY_IN-REALQTY ELSE 0 END ),
		SETTLEMENT=SUM(CASE WHEN LEFT(VCHRNO,2) IN ('DM', 'ST') THEN  REALQTY_IN-REALQTY ELSE 0 END ),
		STOCKBALANCE=SUM(REALQTY_IN)-SUM(REALQTY), BC--,
		--MCAT,DESCA,MENUCODE,BARCODE,MGROUP,MGROUPNAME,MGROUPCODE,SUPPLIER,BASEUNIT,SRATE,BC 
		FROM #RMD_TRNPROD A GROUP BY A.MCODE, A.BC, A.DIVISION--,MCAT,DESCA,MENUCODE,BARCODE,MGROUP,MGROUPNAME,MGROUPCODE,SUPPLIER,BASEUNIT,SRATE,BC
	) A 
	LEFT JOIN 
	(
		SELECT A.MCODE,CASE WHEN @SHOWVALUATIONRATE = 0 THEN ISNULL(CASE WHEN ISNULL(A.CRATE,0) = 0 THEN A.PRATE_A ELSE ISNULL(A.CRATE,0) END,0) ELSE ISNULL(X.RATE,0) END PRATE FROM
		MENUITEM A LEFT JOIN COSTING X ON A.MCODE = X.MCODE
	) B ON A.MCODE = B.MCODE
)A WHERE ((@RepMode = 1 AND STOCKBALANCE <> 0) OR (@RepMode = 2 AND STOCKBALANCE < 0) OR (@RepMode = 3 AND STOCKBALANCE = 0) OR  (@RepMode = 0 AND STOCKBALANCE < 1000000000)) 


--PREPARING RECORD TO SHOW REPORT AS PER REPORT OPTION
--------------------------------------------------------
if object_id('tempdb..#TRNPROD1') IS NOT NULL DROP TABLE #TRNPROD1

CREATE TABLE #TRNPROD1 (ITEMCODE VARCHAR(25) COLLATE DATABASE_DEFAULT,DESCA VARCHAR(200) COLLATE DATABASE_DEFAULT,BARCODE VARCHAR(50) COLLATE DATABASE_DEFAULT,
BASEUNIT VARCHAR(50), DIVISION VARCHAR(20), OPQTY NUMERIC(18,4),PQTY NUMERIC(18,4),TRANSFERIN NUMERIC(18,4),SALESQTY NUMERIC(18,4),TRANSFEROUT NUMERIC(18,4),STOCKADJUSTMENT NUMERIC(18,4),
SETTLEMENT NUMERIC(18,4),STOCKBALANCE NUMERIC(18,4),PRATE NUMERIC(18,4),STOCKVALUE NUMERIC(18,4),SRATE NUMERIC(18,4),SUPPLIER VARCHAR(100) COLLATE DATABASE_DEFAULT,MCODE VARCHAR(100) COLLATE DATABASE_DEFAULT)

--ITEMCODE,DESCA,BARCODE,BASEUNIT,OPQTY,PQTY,TRANSFERIN,SALESQTYY,TRANSFEROUT,STOCKADJUSTMENT,SETTLEMENT,STOCKBALANCE,PRATE,STOCKVALUE,SRATE,SUPPLIER,MCODE

if object_id('tempdb..#TRNPROD') IS NOT NULL DROP TABLE #TRNPROD
SELECT * INTO #TRNPROD FROM 
(
	SELECT CASE @WISE WHEN 'ITEM' THEN B.DESCA WHEN 'ITEMCATEGORY' THEN ISNULL(B.MCAT,'N/A') ELSE ISNULL(C.DESCA,'') END DESCA,
	CASE @WISE WHEN 'ITEM' THEN B.MENUCODE WHEN 'ITEMCATEGORY' THEN '' ELSE ISNULL(C.MENUCODE,'') END ITEMCODE,
	CASE @WISE WHEN 'ITEM' THEN CASE WHEN @BYBARCODE=0 THEN ISNULL(B.BARCODE,B.MENUCODE) ELSE A.BARCODE END ELSE '' END AS BARCODE,
	CASE @WISE WHEN 'ITEM' THEN B.BASEUNIT ELSE '' END BASEUNIT,CASE @WISE WHEN 'ITEM' THEN D.ACNAME ELSE '' END SUPPLIER,
	CASE @WISE WHEN 'ITEM' THEN A.MCODE WHEN 'ITEMCATEGORY' THEN ISNULL(B.MCAT,'N/A') ELSE ISNULL(B.MGROUP,'') END MCODE,
	CASE @WISE WHEN 'ITEM' THEN A.PRATE ELSE 0 END PRATE,
	CASE @WISE WHEN 'ITEM' THEN B.RATE_A ELSE 0 END SRATE,
	OPQTY,PQTY,TRANSFERIN,SALESQTY,TRANSFEROUT,STOCKADJUSTMENT,SETTLEMENT,STOCKBALANCE,STOCKVALUE, A.DIVISION
	FROM #RMD_TRNPROD1 A INNER JOIN MENUITEM B ON A.MCODE= B.MCODE 
	LEFT JOIN MENUITEM C ON B.MGROUP = C.MCODE 
	LEFT JOIN RMD_ACLIST D ON ISNULL(B.SUPCODE,'') = D.ACID
	WHERE ISNULL(B.MCAT,'') LIKE @CATEGORY AND ISNULL(B.MGROUP,'') LIKE @ITEMGROUP AND ISNULL(B.SUPCODE,'') LIKE @SUPPLIER AND
	((@PATH='%' AND ISNULL(B.PATH,'') LIKE @PATH) OR (@PATH <> '%' 
	AND B.PARENT IN (SELECT MCODE FROM DBO.TreeExpand_function(@PATH,'PATH','1'))))
	AND ((@PTYPE=100 AND ISNULL(B.PTYPE,0)<10) OR (@PTYPE <> 100 AND ISNULL(B.PTYPE,0) = @PTYPE))
)A

INSERT INTO #TRNPROD1
(ITEMCODE,DESCA,BARCODE,BASEUNIT,DIVISION,OPQTY,PQTY,TRANSFERIN,SALESQTY,TRANSFEROUT,STOCKADJUSTMENT,SETTLEMENT,STOCKBALANCE,PRATE,STOCKVALUE,SRATE,SUPPLIER,MCODE)
SELECT * FROM
(
	SELECT ITEMCODE,DESCA,BARCODE,BASEUNIT,DIVISION,
	SUM(OPQTY) OPQTY,SUM(PQTY) PQTY,SUM(TRANSFERIN) TRANSFERIN,SUM(SALESQTY) SALESQTY,SUM(TRANSFEROUT) TRANSFEROUT,
	SUM(STOCKADJUSTMENT) STOCKADJUSTMENT,SUM(SETTLEMENT) SETTLEMENT,SUM(STOCKBALANCE) STOCKBALANCE,
	ISNULL(A.PRATE,0) PRATE,SUM(STOCKVALUE) STOCKVALUE,A.SRATE,A.SUPPLIER,A.MCODE
	FROM #TRNPROD A GROUP BY A.ITEMCODE,A.DESCA,A.BARCODE,A.BASEUNIT,ISNULL(A.PRATE,0),A.SRATE,A.SUPPLIER,A.MCODE, A.DIVISION
) A
	
 
--PREPARING REPORT 
-------------------
--CREATING TEMPORTY TABLE TO HOLD THE REPORT OUTPUT
----------------------------------------------------
IF OBJECT_ID('TEMPDB..#RESULT') IS NOT NULL DROP TABLE #RESULT

CREATE TABLE #RESULT (ITEMCODE VARCHAR(25),DESCA VARCHAR(200),BARCODE VARCHAR(50), DIVISION VARCHAR(20),
COLOR VARCHAR(50),SIZE VARCHAR(50),MAKE VARCHAR(50),GENDER VARCHAR(50),ORIGIN VARCHAR(50),FIT VARCHAR(50),SEASON VARCHAR(50),MEASUREMENT VARCHAR(50),ITYPE VARCHAR(50),
BASEUNIT VARCHAR(50),OPQTY NUMERIC(18,4),PQTY NUMERIC(18,4),TRANSFERIN NUMERIC(18,4),SALESQTY NUMERIC(18,4),TRANSFEROUT NUMERIC(18,4),STOCKADJUSTMENT NUMERIC(18,4),
SETTLEMENT NUMERIC(18,4),STOCKBALANCE NUMERIC(18,4),PRATE NUMERIC(18,4),STOCKVALUE NUMERIC(18,4),SRATE NUMERIC(18,4),SUPPLIER VARCHAR(100),MCODE VARCHAR(100),
ENGINENO VARCHAR(50), CHASISNO VARCHAR(50), VEHICLEREGNO VARCHAR(50), VEHICLEMODEL VARCHAR(50))

if @SHOWBARCODEDETAIL = 0
	BEGIN
		IF @BYBARCODE = 0 OR @WISE <> 'ITEM'
			INSERT INTO #RESULT
			SELECT ITEMCODE,DESCA,BARCODE,DIVISION,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,BASEUNIT,
			SUM(OPQTY)OPQTY,SUM(PQTY)PQTY,SUM(TRANSFERIN)TRANSFERIN,SUM(SALESQTY)SALESQTY,
			SUM(TRANSFEROUT)TRANSFEROUT,SUM(STOCKADJUSTMENT) STOCKADJUSTMENT,SUM(SETTLEMENT) SETTLEMENT,
			SUM(STOCKBALANCE) STOCKBALANCE, PRATE,SUM(STOCKVALUE)STOCKVALUE,A.SRATE,A.SUPPLIER,A.MCODE,
                        NULL, NULL, NULL, NULL
			FROM #TRNPROD1 A 
			GROUP BY A.ITEMCODE,A.DESCA,A.BARCODE,A.BASEUNIT,A.PRATE,A.SRATE,A.SUPPLIER,A.MCODE, A.DIVISION
			ORDER BY A.DESCA
		ELSE
			INSERT INTO #RESULT
			SELECT ITEMCODE,DESCA,B.BCODE,DIVISION,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,BASEUNIT,
			SUM(OPQTY)OPQTY,SUM(PQTY)PQTY,SUM(TRANSFERIN)TRANSFERIN,SUM(SALESQTY)SALESQTY,
			SUM(TRANSFEROUT)TRANSFEROUT,SUM(STOCKADJUSTMENT) STOCKADJUSTMENT,SUM(SETTLEMENT) SETTLEMENT,
			SUM(STOCKBALANCE) STOCKBALANCE, PRATE,SUM(STOCKVALUE)STOCKVALUE,CASE WHEN @BCWISERATE = 0 THEN A.SRATE ELSE B.SRATE_BC END SRATE,
			ISNULL(B.SUPPLIERNAME,A.SUPPLIER) SUPPLIER,A.MCODE,NULL, NULL, NULL, NULL
			FROM #TRNPROD1 A CROSS APPLY 
			(
				SELECT TOP 1 B.BCODE,B.MCODE,AC.ACNAME,SRATE SRATE_BC,AC.ACNAME SUPPLIERNAME FROM BARCODE B 
				LEFT JOIN RMD_ACLIST AC ON ISNULL(B.SUPCODE,'') = AC.ACID WHERE B.MCODE = A.MCODE
			) B 
			GROUP BY A.ITEMCODE,A.DESCA,B.BCODE,A.BASEUNIT,A.PRATE,
			CASE WHEN @BCWISERATE = 0 THEN A.SRATE ELSE B.SRATE_BC END,ISNULL(B.SUPPLIERNAME,A.SUPPLIER),A.MCODE, A.DIVISION
			ORDER BY A.DESCA
	END
ELSE
	INSERT INTO #RESULT	
	SELECT ITEMCODE,DESCA,BARCODE,DIVISION,COLOR,SIZE,MAKE,GENDER,ORIGIN,FIT,SEASON,MEASUREMENT,ITYPE,BASEUNIT,
	SUM(OPQTY)OPQTY,SUM(PQTY)PQTY,SUM(TRANSFERIN)TRANSFERIN,SUM(SALESQTY)SALESQTY,
	SUM(TRANSFEROUT)TRANSFEROUT,SUM(STOCKADJUSTMENT) STOCKADJUSTMENT,SUM(SETTLEMENT) SETTLEMENT,
	SUM(STOCKBALANCE) STOCKBALANCE, PRATE,SUM(STOCKVALUE)STOCKVALUE,A.SRATE,ISNULL(SUPPLIERNAME,A.SUPPLIER)SUPPLIER,A.MCODE, ENGINENO, CHASISNO, VEHICLEREGNO, VEHICLEMODEL
	FROM 
	(
		SELECT A.*,B.COLOR,B.SIZE,B.MAKE,B.GENDER,B.ORIGIN,B.FIT,B.SEASON,B.MEASUREMENT, B.[TYPE] ITYPE,X.SUPPLIERNAME, 
		ISNULL(B.VEHICLEENGINENO, '') ENGINENO, ISNULL(B.VEHICLECHASISNO, '') CHASISNO, ISNULL(B.VEHICLEREGISTRATIONNO, '') VEHICLEREGNO, ISNULL(B.VEHICLEMODEL, '') VEHICLEMODEL
		FROM #TRNPROD1 A 
		LEFT JOIN BARCODE_DETAIL B ON A.MCODE = B.MCODE AND A.BARCODE = B.BARCODE 
		LEFT JOIN
		(
			SELECT TOP 1 A.BCODE,A.MCODE,B.ACNAME SUPPLIERNAME FROM BARCODE A INNER JOIN RMD_ACLIST B ON ISNULL(A.SUPCODE,'') = B.ACID
		) X ON A.MCODE = X.MCODE
	) A 
	GROUP BY A.MCODE,A.DESCA,A.ITEMCODE,A.BARCODE,A.BASEUNIT,ISNULL(SUPPLIERNAME,A.SUPPLIER),A.PRATE,A.SRATE,A.COLOR,A.SIZE,A.MAKE,
	GENDER,ORIGIN,FIT,SEASON,MEASUREMENT,ITYPE, ENGINENO, CHASISNO, VEHICLEREGNO, VEHICLEMODEL, A.DIVISION
	ORDER BY A.DESCA

IF @TREEFORMAT=0
	SELECT ITEMCODE, DESCA, BARCODE, COLOR,SIZE, MAKE, GENDER, ORIGIN, FIT, SEASON, MEASUREMENT, ITYPE, BASEUNIT, OPQTY, PQTY, TRANSFERIN, SALESQTY, 
	TRANSFEROUT, STOCKADJUSTMENT,SETTLEMENT, STOCKBALANCE, PRATE, STOCKVALUE, SRATE, SUPPLIER, MCODE, ENGINENO, CHASISNO, VEHICLEREGNO, VEHICLEMODEL, [TYPE]
	FROM
	(
		SELECT DISTINCT '' ITEMCODE,d.[name] DESCA,''BARCODE,DIVISION,NULL COLOR,NULL SIZE,NULL MAKE,NULL GENDER,NULL ORIGIN,NULL FIT,NULL SEASON,
		NULL MEASUREMENT,NULL ITYPE,NULL BASEUNIT,NULL OPQTY,NULL PQTY,NULL TRANSFERIN,	NULL SALESQTY,NULL TRANSFEROUT,NULL  STOCKADJUSTMENT,
		NULL SETTLEMENT, NULL STOCKBALANCE,NULL PRATE,NULL STOCKVALUE,NULL SRATE,NULL SUPPLIER,NULL MCODE, NULL ENGINENO,NULL CHASISNO,
		NULL VEHICLEREGNO,NULL VEHICLEMODEL ,1 flg, 'G' TYPE
		from #RESULT a left join division d on a.DIVISION=d.INITIAL
		
		UNION ALL
		SELECT *,2 FLG, 'A' TYPE FROM #RESULT 
	
		UNION ALL
		SELECT  ''ITEMCODE,'    TOTAL>>'DESCA,''BARCODE,DIVISION,''COLOR,NULL SIZE,NULL MAKE,NULL GENDER,NULL ORIGIN,NULL FIT,NULL SEASON,NULL MEASUREMENT,NULL ITYPE,NULL BASEUNIT,SUM(ISNULL(OPQTY,0)),
		SUM(ISNULL(PQTY,0)),SUM(ISNULL(TRANSFERIN,0)),SUM(ISNULL(SALESQTY,0)),SUM(ISNULL(TRANSFEROUT,0)), SUM(ISNULL(STOCKADJUSTMENT,0)),SUM(ISNULL(SETTLEMENT,0)),
		SUM(ISNULL(STOCKBALANCE,0)), NULL PRATE,SUM(ISNULL(STOCKVALUE,0)),NULL SRATE,NULL SUPPLIER,NULL MCODE, NULL ENGINENO,NULL CHASISNO,NULL VEHICLEREGNO,NULL VEHICLEMODEL ,3 FLG, 'G' TYPE
		from  #RESULT GROUP BY DIVISION

		UNION ALL
		SELECT DISTINCT '', NULL, NULL, DIVISION, NULL, NULL, NULL, NULL, NULL, NULL, NULL,	NULL, NULL, NULL, NULL, NULL, NULL,	NULL, NULL, NULL,
		NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,	NULL, NULL, 4 flg, 'A' TYPE
		from #RESULT a left join division d on a.DIVISION=d.INITIAL

	)a ORDER BY DIVISION,flg,DESCA
ELSE
	BEGIN
		DECLARE @GROUPNAME AS VARCHAR(100)
		IF @GROUP='MI' 
			BEGIN
				SET @GROUPNAME = 'PRODUCTLIST'
			END
		ELSE
			BEGIN
				SELECT @GROUPNAME=Desca FROM MENUITEM WHERE MCODE=@GROUP 
			END 
		
		if @SHOWBARCODEDETAIL = 0
			BEGIN
				IF OBJECT_ID('TEMPDB..#TREE') IS NOT NULL DROP TABLE #TREE
				--PREPARING TREE
				SELECT CASE WHEN A.TYPE='G' THEN '-' ELSE NULL END AS SYMBOL, A.TYPE,A.LEVEL,A.DESCRIPTION,A.CODE,B.BARCODE,
				NULL COLOR,NULL SIZE,NULL MAKE,NULL GENDER,NULL ORIGIN,NULL FIT,NULL SEASON,NULL MEASUREMENT,NULL ITYPE,
				B.BASEUNIT,OPQTY,PQTY,TRANSFERIN,SALESQTY,TRANSFEROUT,STOCKADJUSTMENT,SETTLEMENT,STOCKBALANCE,PRATE,STOCKVALUE,SUPPLIER,
				A.PARENT,A.ID,A.MCODE, B.DIVISION INTO #TREE FROM TreeExpand_function (@GROUP ,@GROUPNAME ,0) AS A
				LEFT JOIN #RESULT B ON A.MCODE = B.MCODE

				INSERT INTO #TREE
				SELECT  DISTINCT A.SYMBOL, A.TYPE,A.LEVEL,A.DESCRIPTION,A.CODE,NULL BARCODE,
         		A.COLOR,A.SIZE,A.MAKE,A.GENDER,A.ORIGIN,A.FIT,A.SEASON,A.MEASUREMENT,A.ITYPE,
         		A.BASEUNIT,A.OPQTY,A.PQTY,A.TRANSFERIN,A.SALESQTY,A.TRANSFEROUT,A.STOCKADJUSTMENT,A.SETTLEMENT,A.STOCKBALANCE,A.PRATE,A.STOCKVALUE,A.SUPPLIER,
         		A.PARENT,A.ID,A.MCODE,B.DIVISION FROM #TREE a,#TREE b WHERE A.TYPE='G'AND B.DIVISION IS NOT NULL

				--SUMMING GROUP
				DECLARE @LVL INT
				select @LVL=MAX(LEVEL) from #TREE 

				WHILE @lvl > 0
				BEGIN
					update A set A.OPQTY  =B.OPQTY  ,A.PQTY  =B.PQTY  , A.TRANSFERIN  =B.TRANSFERIN ,A.SALESQTY =B.SALESQTY ,A.TRANSFEROUT =B.TRANSFEROUT  ,
					A.STOCKADJUSTMENT =B.STOCKADJUSTMENT ,A.SETTLEMENT =B.SETTLEMENT  ,A.PRATE =B.PRATE  ,A.STOCKVALUE =B.STOCKVALUE,A.STOCKBALANCE=B.STOCKBALANCE 
					from #TREE A INNER JOIN 
					(
						select Parent, DIVISION, SUM(OPQTY) OPQTY,SUM(PQTY  ) PQTY,SUM(TRANSFERIN ) TRANSFERIN,SUM(SALESQTY ) SALESQTY,SUM(TRANSFEROUT ) TRANSFEROUT,
						SUM(STOCKADJUSTMENT ) STOCKADJUSTMENT,SUM(SETTLEMENT ) SETTLEMENT,SUM(STOCKBALANCE ) STOCKBALANCE,AVG(PRATE ) PRATE,SUM(STOCKVALUE ) STOCKVALUE 
						from #TREE where level= @LVL group by parent, DIVISION
					) B on A.MCODE =B.Parent AND A.DIVISION = B.DIVISION
					SET @lvl = @lvl - 1;
				END
				SELECT * FROM 
				(
					SELECT  DISTINCT NULL SYMBOL,NULL TYPE,NULL LEVEL,D.[NAME] DESCRIPTION,NULL CODE,NULL BARCODE,NULL COLOR,NULL SIZE,NULL MAKE,
					NULL GENDER,NULL ORIGIN,NULL FIT,NULL SEASON,NULL MEASUREMENT,NULL ITYPE,NULL BASEUNIT,	NULL OPQTY,NULL PQTY,NULL TRANSFERIN,
					NULL SALESQTY,NULL TRANSFEROUT,NULL STOCKADJUSTMENT,NULL SETTLEMENT,NULL STOCKBALANCE,NULL PRATE,NULL STOCKVALUE,NULL SUPPLIER,
					NULL PARENT, -1 ID,NULL MCODE,DIVISION,'A' FLG 
					FROM #TREE A LEFT  JOIN DIVISION D ON A.DIVISION=D.INITIAL 
					WHERE DIVISION IS NOT NULL
					
					UNION ALL
         			SELECT *,'B' FLG FROM #TREE where OPQTY <> 0 or PQTY <>0 or TRANSFERIN=0 or TRANSFEROUT=0 or SALESQTY <> 0 or TRANSFEROUT <> 0 or STOCKADJUSTMENT <> 0 or SETTLEMENT <> 0 
					
					UNION ALL					
					SELECT  NULL SYMBOL,NULL TYPE,NULL LEVEL,'    TOTAL>>' DESCRIPTION,NULL CODE,NULL BARCODE,NULL COLOR,NULL SIZE,NULL MAKE,NULL GENDER,
					NULL ORIGIN,NULL FIT,NULL SEASON,NULL MEASUREMENT,NULL ITYPE,NULL BASEUNIT,	SUM(ISNULL(OPQTY,0)),SUM(ISNULL(PQTY,0)),
					SUM(ISNULL(TRANSFERIN,0)),SUM(ISNULL(SALESQTY,0)),SUM(ISNULL(TRANSFEROUT,0)), SUM(ISNULL(STOCKADJUSTMENT,0)),SUM(ISNULL(SETTLEMENT,0)),
      				SUM(ISNULL(STOCKBALANCE,0)), NULL PRATE,SUM(ISNULL(STOCKVALUE,0)),NULL SUPPLIER,NULL PARENT,
					100000 ID,NULL MCODE,DIVISION,'C' FLG 
					FROM #TREE WHERE TYPE='A' and  DIVISION IS NOT NULL GROUP BY DIVISION
				)A
				ORDER BY division,ID,FLG
				--SELECT * FROM #TREE where OPQTY <> 0 or PQTY <>0 or TRANSFERIN=0 or TRANSFEROUT=0 or SALESQTY <> 0 or TRANSFEROUT <> 0 or STOCKADJUSTMENT <> 0 or SETTLEMENT <> 0 
			END
		ELSE
			BEGIN
				IF OBJECT_ID('TEMPDB..#TREE1') IS NOT NULL DROP TABLE #TREE1
				--PREPARING TREE
				SELECT CASE WHEN A.TYPE='G' THEN '-' ELSE NULL END AS SYMBOL, A.TYPE,A.LEVEL,A.DESCRIPTION,A.CODE,B.BARCODE,
				COLOR,SIZE,MAKE,GENDER,ORIGIN,FIT,SEASON,MEASUREMENT,ITYPE,
				B.BASEUNIT,OPQTY,PQTY,TRANSFERIN,SALESQTY,TRANSFEROUT,STOCKADJUSTMENT,SETTLEMENT,STOCKBALANCE,PRATE,STOCKVALUE,SUPPLIER,
				A.PARENT,A.ID,A.MCODE, B.DIVISION INTO #TREE1 FROM TreeExpand_function (@GROUP ,@GROUPNAME ,0) AS A
				LEFT JOIN #RESULT B ON A.MCODE = B.MCODE

				--SUMMING GROUP
				--DECLARE @LVL INT
				select @LVL=MAX(LEVEL) from #TREE1 

				WHILE @lvl > 0
				BEGIN
					update A set A.OPQTY  =B.OPQTY  ,A.PQTY  =B.PQTY  , A.TRANSFERIN  =B.TRANSFERIN ,A.SALESQTY =B.SALESQTY ,A.TRANSFEROUT =B.TRANSFEROUT  ,
					A.STOCKADJUSTMENT =B.STOCKADJUSTMENT ,A.SETTLEMENT =B.SETTLEMENT  ,A.PRATE =B.PRATE  ,A.STOCKVALUE =B.STOCKVALUE,A.STOCKBALANCE=B.STOCKBALANCE 
					from #TREE1 A INNER JOIN 
					(
						select Parent, DIVISION,SUM(OPQTY) OPQTY,SUM(PQTY  ) PQTY,SUM(TRANSFERIN ) TRANSFERIN,SUM(SALESQTY ) SALESQTY,SUM(TRANSFEROUT ) TRANSFEROUT,
						SUM(STOCKADJUSTMENT ) STOCKADJUSTMENT,SUM(SETTLEMENT ) SETTLEMENT,SUM(STOCKBALANCE ) STOCKBALANCE,AVG(PRATE ) PRATE,SUM(STOCKVALUE ) STOCKVALUE 
						from #TREE1 where level= @LVL group by parent, DIVISION
					) B on A.MCODE =B.Parent AND A.DIVISION = B.DIVISION
					SET @lvl = @lvl - 1;
				END

				SELECT * FROM 
				(
					SELECT  DISTINCT NULL SYMBOL,NULL TYPE,NULL LEVEL,D.[NAME] DESCRIPTION,NULL CODE,NULL BARCODE,NULL COLOR,NULL SIZE,NULL MAKE,NULL GENDER,
					NULL ORIGIN,NULL FIT,NULL SEASON,NULL MEASUREMENT,NULL ITYPE,NULL BASEUNIT,	NULL OPQTY,NULL PQTY,NULL TRANSFERIN,NULL SALESQTY,
					NULL TRANSFEROUT,NULL STOCKADJUSTMENT,NULL SETTLEMENT,NULL STOCKBALANCE,NULL PRATE,NULL STOCKVALUE,NULL SUPPLIER,NULL PARENT,
					-1 ID,NULL MCODE,DIVISION,'A' FLG 
					FROM #TREE1  A LEFT  JOIN DIVISION D ON A.DIVISION=D.INITIAL 
					WHERE DIVISION IS NOT NULL

					UNION ALL
         			SELECT *,'B' FLG FROM #TREE1 where OPQTY <> 0 or PQTY <>0 or TRANSFERIN=0 or TRANSFEROUT=0 or SALESQTY <> 0 or TRANSFEROUT <> 0 or STOCKADJUSTMENT <> 0 or SETTLEMENT <> 0 
				
					UNION ALL
					SELECT  NULL SYMBOL,NULL TYPE,NULL LEVEL,'    TOTAL>>' DESCRIPTION,NULL CODE,NULL BARCODE,NULL COLOR,NULL SIZE,NULL MAKE,NULL GENDER,
					NULL ORIGIN,NULL FIT,NULL SEASON,NULL MEASUREMENT,NULL ITYPE,NULL BASEUNIT,	SUM(ISNULL(OPQTY,0)),SUM(ISNULL(PQTY,0)),
					SUM(ISNULL(TRANSFERIN,0)),SUM(ISNULL(SALESQTY,0)),SUM(ISNULL(TRANSFEROUT,0)), SUM(ISNULL(STOCKADJUSTMENT,0)),SUM(ISNULL(SETTLEMENT,0)),
      	            SUM(ISNULL(STOCKBALANCE,0)), NULL PRATE,SUM(ISNULL(STOCKVALUE,0)),NULL SUPPLIER,NULL PARENT,
					100000 ID,NULL MCODE,DIVISION,'C' FLG 
					FROM #TREE1 WHERE [TYPE]='A' and  DIVISION IS NOT NULL GROUP BY DIVISION
				)A
				ORDER BY division,ID,FLG
			END			
END

IF OBJECT_ID('TEMPDB..#RESULT') IS NOT NULL DROP TABLE #RESULT
if object_id('tempdb..#TRNPROD1') IS NOT NULL DROP TABLE #TRNPROD1
if object_id('tempdb..#TRNPROD') IS NOT NULL DROP TABLE #TRNPROD
IF OBJECT_ID('TEMPDB..#RMD_TRNPROD') IS NOT NULL DROP TABLE #RMD_TRNPROD
IF OBJECT_ID('TEMPDB..#TREE1') IS NOT NULL DROP TABLE #TREE1
IF OBJECT_ID('TEMPDB..#TREE') IS NOT NULL DROP TABLE #TREE
IF OBJECT_ID('TEMPDB..#tblWarehouse') is not NULL drop table #tblWarehouse