CREATE OR ALTER   PROCEDURE [dbo].[NSP_SALESREPORT_ITEMWISE]
--DECLARE 
	@DATE1 DATETIME,
	@DATE2 DATETIME,
	@DIV VARCHAR(3) = '%',
	@MC VARCHAR(25) = '%',
	@BC VARCHAR(MAX)= '%',
	@PATH VARCHAR(MAX) = '%',
	@MGROUP VARCHAR(25) = '%',
	@MCAT VARCHAR(50) = '%',
	@PTYPE INT = 100,
	@PARTY VARCHAR(25) = '%',
	@CUSTOMERPARTY VARCHAR(25) = '%',
	@ITEMLIST VARCHAR(MAX) = '',
	@SHOWINTERCOMPANYONLY TINYINT = 0,
	@BARCODEWISEREPORT TINYINT = 0,
	@DIVISIONWISEREPORT TINYINT = 0,
	@WISE VARCHAR(25) = 'ITEM',
	@ATTRIBUTE VARCHAR(100) = '%',			--'COLOR LIKE ''RED'''
	@TREE TINYINT = 0,
	@FLAG TINYINT = 0 ---0 filter by TRNDATE |1 filter by DAYSTARTDATE
AS

--SET @DATE1 = '2023-07-17'; SET @DATE2 = '2025-07-17' ; SET @DIVISIONWISEREPORT = 0; 
--SET @CUSTOMERPARTY='PA577'
--SET @FLAG = 0

 
set nocount on

DECLARE @SHOWBARCODEDETAIL TINYINT=1
DECLARE @BCDETAIL_QUERY VARCHAR(500)
DECLARE  @BARCODECOMPULOSRYMODE TINYINT = 0

SELECT @BCDETAIL_QUERY = 'SELECT BARCODE,SIZE,COLOR,GENDER,TYPE,MCODE FROM BARCODE_DETAIL',@SHOWBARCODEDETAIL = ISNULL(EnableBarcodeDetails,0),@BARCODECOMPULOSRYMODE = 0 FROM SETTING WITH (NOLOCK)

IF OBJECT_ID('TEMPDB..#MENUITEM') is not null drop table #MENUITEM
CREATE TABLE #MENUITEM (MCODE VARCHAR(25),MENUCODE VARCHAR(50),DESCA VARCHAR(100),MGROUP VARCHAR(25),MCAT VARCHAR(50),BASEUNIT VARCHAR(25),SUPCODE VARCHAR(25),PTYPE TINYINT,PATH VARCHAR(2000))

if @ITEMLIST = ''
	INSERT INTO #MENUITEM (MCODE,MENUCODE,DESCA,MGROUP,MCAT,BASEUNIT,SUPCODE,PTYPE,PATH)
	SELECT MCODE,MENUCODE,DESCA,MGROUP,MCAT,BASEUNIT,SUPCODE,PTYPE,PATH FROM MENUITEM WITH (NOLOCK) 
	WHERE TYPE = 'A' AND MGROUP LIKE @MGROUP AND ISNULL(MCAT, '') LIKE @MCAT AND	((@PTYPE = 100 AND ISNULL(PTYPE,0) < @PTYPE) OR (@PTYPE <> 100 AND ISNULL(PTYPE,0) = @PTYPE)) AND ISNULL(PATH,'') LIKE @PATH AND ISNULL(SUPCODE,'') LIKE @PARTY	
ELSE
	BEGIN
		IF @BARCODECOMPULOSRYMODE = 0
			BEGIN
				INSERT INTO #MENUITEM (MCODE,MENUCODE,DESCA,MGROUP,MCAT,BASEUNIT,SUPCODE,PTYPE,PATH) 
				SELECT MCODE,MENUCODE,DESCA,MGROUP,MCAT,BASEUNIT,SUPCODE,PTYPE,PATH FROM MENUITEM A WITH (NOLOCK) INNER JOIN 
				(select * from dbo.split(@ITEMLIST,',')) B ON A.MCODE = B.ITEMS
				WHERE MGROUP LIKE @MGROUP AND ISNULL(MCAT, '') LIKE @MCAT AND	((@PTYPE = 100 AND ISNULL(PTYPE,0) < @PTYPE) OR (@PTYPE <> 100 AND ISNULL(PTYPE,0) = @PTYPE)) AND ISNULL(PATH,'') LIKE @PATH AND ISNULL(SUPCODE,'') LIKE @PARTY	
				
				SET @ITEMLIST = ''
			END
		ELSE
			BEGIN
				SET @BC = @ITEMLIST
				INSERT INTO #MENUITEM (MCODE,MENUCODE,DESCA,MGROUP,MCAT,BASEUNIT,SUPCODE,PTYPE,PATH)
				SELECT A.MCODE,A.MENUCODE,A.DESCA,A.MGROUP,A.MCAT,A.BASEUNIT,A.SUPCODE,A.PTYPE,A.PATH FROM MENUITEM A WITH (NOLOCK) INNER JOIN 
				(SELECT DISTINCT MCODE FROM BARCODE A WITH (NOLOCK) INNER JOIN (select * from dbo.split(@ITEMLIST,',')) B ON A.BCODE = B.ITEMS) B
				ON A.MCODE = B.MCODE
				WHERE A.MGROUP LIKE @MGROUP AND ISNULL(A.MCAT, '') LIKE @MCAT AND	((@PTYPE = 100 AND ISNULL(A.PTYPE,0) < @PTYPE) OR (@PTYPE <> 100 AND ISNULL(A.PTYPE,0) = @PTYPE)) AND ISNULL(PATH,'') LIKE @PATH AND ISNULL(A.SUPCODE,'') LIKE @PARTY	
			END
	END
	--PRINT @BC

BEGIN
	IF @ATTRIBUTE <> '' AND @ATTRIBUTE <> '%'
		SET @BCDETAIL_QUERY = @BCDETAIL_QUERY + N' WHERE ' + @ATTRIBUTE
END

	IF OBJECT_ID('TEMPDB..#REPDATA') is not null drop table #REPDATA
	
	SELECT B.MCODE, IIF(@FLAG=1, D.DAYDATE,	A.TRNDATE) TRNDATE,DM.MITI BSDATE,A.DIVISION,X.MENUCODE,X.DESCA,ISNULL(B.BC,'') BC,
	ISNULL(REALQTY,0) SALESQTY, ISNULL(REALQTY_IN,0) RETURNQTY,
	ISNULL(REALQTY,0)-ISNULL(REALQTY_IN,0) NETQTY,	CASE WHEN LEFT(B.VCHRNO,2) IN ('CN','RE','IR') THEN B.AMOUNT*-1 ELSE B.AMOUNT END TOTVALUE,
	CASE WHEN LEFT(B.VCHRNO,2) IN ('CN','RE','IR') THEN B.DISCOUNT*-1 ELSE B.DISCOUNT END DISCOUNT,
	CASE WHEN LEFT(B.VCHRNO,2) IN ('CN','RE','IR') THEN B.SERVICETAX *-1 ELSE B.SERVICETAX END SCHARGE,
	CASE WHEN LEFT(B.VCHRNO,2) IN ('CN','RE','IR') THEN (B.TAXABLE+B.NONTAXABLE) *-1 ELSE (B.TAXABLE+B.NONTAXABLE) END NETSALE,
	CASE WHEN LEFT(B.VCHRNO,2) IN ('CN','RE','IR') THEN B.TAXABLE*-1 ELSE B.TAXABLE END TAXABLE,
	CASE WHEN LEFT(B.VCHRNO,2) IN ('CN','RE','IR') THEN B.NONTAXABLE*-1 ELSE B.NONTAXABLE END NONTAXABLE,
	CASE WHEN LEFT(B.VCHRNO,2) IN ('CN','RE','IR') THEN B.VAT*-1 ELSE B.VAT END VAMNT,
	CASE WHEN LEFT(B.VCHRNO,2) IN ('CN','RE','IR') THEN (B.TAXABLE+B.NONTAXABLE+B.VAT)*-1 ELSE (B.TAXABLE+B.NONTAXABLE+B.VAT) END NETAMNT,
	X.MGROUP,X.MCAT,X.BASEUNIT UNIT,CASE WHEN @DIVISIONWISEREPORT = 1 THEN Y.NAME ELSE '' END DIVISION_NAME,ISNULL(X.SUPCODE,'')SUPCODE,ISNULL(X.PTYPE,0) PTYPE
	INTO #REPDATA
	FROM RMD_SALESPROD B WITH (NOLOCK)
	INNER JOIN RMD_TRNMAIN A WITH (NOLOCK) ON A.VCHRNO = B.VCHRNO
	INNER JOIN #MENUITEM X ON B.MCODE = X.MCODE 
	LEFT JOIN DIVISION Y WITH (NOLOCK) ON B.DIVISION = Y.INITIAL
	LEFT JOIN vwSessionDay D WITH (NOLOCK) ON A.[SHIFT] = D.SESSIONID
	LEFT JOIN DateMiti DM WITH (NOLOCK) ON IIF(@FLAG=1, D.DAYDATE, A.TRNDATE) = DM.AD
	WHERE ((@SHOWINTERCOMPANYONLY=0 AND LEFT(A.VCHRNO,2) IN ('SI','TI','CN','RE')) OR (@SHOWINTERCOMPANYONLY=1 AND LEFT(A.VCHRNO,2) IN ('IC','IR')))
	AND IIF(@FLAG=1, D.DAYDATE,	A.TRNDATE) BETWEEN @DATE1 AND @DATE2 AND A.DIVISION LIKE @DIV AND B.MCODE LIKE @MC 	
	AND ((@ITEMLIST = '' AND ISNULL(B.BC,'') LIKE @BC) OR (@ITEMLIST <> '' AND ISNULL(B.BC,'') IN (SELECT * FROM dbo.split(@BC,','))))
	 AND (@CUSTOMERPARTY='%' OR (@CUSTOMERPARTY <> '%' AND ((TRNMODE = 'CREDIT' AND ISNULL(PARAC,A.TRNAC) = @CUSTOMERPARTY) OR (TRNMODE <> 'CREDIT' AND COALESCE(RECEIVEBY,PARAC,A.TRNAC) =@CUSTOMERPARTY))))
 
	
IF @TREE = 0 
	BEGIN
		IF @WISE = 'ITEM'
		BEGIN
			IF @SHOWBARCODEDETAIL = 0
				SELECT * FROM
				(
					SELECT B.[Main Group], B.[Main Category], B.[Sub Category], B.[Super Category], A.MENUCODE, A.DESCA, IIF(@BARCODEWISEREPORT = 1,BC,'') BC,UNIT,SUM(SALESQTY)SQTY,SUM(RETURNQTY)RQTY,SUM(NETQTY)NETQTY,SUM(TOTVALUE) TOTVALUE, SUM(DISCOUNT)DISCOUNT, SUM(SCHARGE)SCHARGE, SUM(NETSALE) NETSALE, SUM(TAXABLE)TAXABLE,
					SUM(NONTAXABLE)NONTAXABLE,SUM(VAMNT) VAMNT,SUM(NETAMNT) NETAMNT,X.ACNAME SUPPLIER,DIVISION_NAME,A.MCODE,'A' FLG FROM #REPDATA A 
					LEFT JOIN RMD_ACLIST X ON A.SUPCODE = X.ACID
					LEFT JOIN vwItemHeirarchy B ON A.MCODE = B.MCODE
					GROUP BY B.[Main Group], B.[Main Category], B.[Sub Category], B.[Super Category], A.MENUCODE,A.DESCA, A.MCODE, IIF(@BARCODEWISEREPORT = 1,BC,''), UNIT,DIVISION_NAME,X.ACNAME
					UNION ALL
					SELECT NULL, NULL, NULL, NULL, '' MENUCODE, 'TOTAL >>' DESCA,NULL BC,NULL UNIT,SUM(SALESQTY)SQTY,SUM(RETURNQTY)RQTY,SUM(NETQTY)NETQTY,SUM(TOTVALUE) TOTVALUE, SUM(DISCOUNT)DISCOUNT, SUM(SCHARGE)SCHARGE, SUM(NETSALE) NETSALE, SUM(TAXABLE)TAXABLE,
					SUM(NONTAXABLE)NONTAXABLE,SUM(VAMNT) VAMNT,SUM(NETAMNT) NETAMNT,NULL SUPPLIER,NULL DIVISION_NAME,NULL MCODE,'B' FLG FROM #REPDATA A 
				) A ORDER BY FLG,DESCA,DIVISION_NAME

				ELSE
				BEGIN
					DECLARE @SQL VARCHAR(MAX)
					SET @SQL = N'
					SELECT MENUCODE,DESCA,UNIT,SQTY,RQTY,NETQTY,TOTVALUE,DISCOUNT,SCHARGE,NETSALE,TAXABLE,NONTAXABLE,VAMNT,NETAMNT,SUPPLIER,B.*,DIVISION_NAME FROM
					(
						SELECT MENUCODE, DESCA,BC,SUM(SALESQTY)SQTY,SUM(RETURNQTY)RQTY,SUM(NETQTY)NETQTY, UNIT,SUM(TOTVALUE) TOTVALUE, SUM(DISCOUNT)DISCOUNT, SUM(SCHARGE)SCHARGE, SUM(NETSALE) NETSALE, SUM(TAXABLE)TAXABLE,
						SUM(NONTAXABLE)NONTAXABLE,SUM(VAMNT) VAMNT,SUM(NETAMNT) NETAMNT,MCODE,X.ACNAME SUPPLIER, DIVISION_NAME FROM #REPDATA A LEFT JOIN RMD_ACLIST X ON A.SUPCODE = X.ACID
						GROUP BY MENUCODE,DESCA,MCODE,UNIT,BC,DIVISION_NAME,X.ACNAME
					) A LEFT JOIN (' + @BCDETAIL_QUERY + ') B ON A.MCODE = B.MCODE AND A.BC = B.BARCODE ORDER BY A.DESCA,A.BC,A.DIVISION_NAME'					
					--print @sql
					EXEC(@SQL)
				END
		END
		ELSE IF @WISE = 'MGROUP'
			SELECT * FROM 
			(
				SELECT NULL CODE,B.DESCA MAINGROUP,NULL BC,NULL UNIT, SUM(SALESQTY)SQTY,SUM(RETURNQTY)RQTY,SUM(NETQTY)NETQTY, SUM(TOTVALUE) TOTVALUE, SUM(DISCOUNT)DISCOUNT, SUM(SCHARGE)SCHARGE, SUM(NETSALE) NETSALE, SUM(TAXABLE)TAXABLE,
				SUM(NONTAXABLE)NONTAXABLE,SUM(VAMNT) VAMNT,SUM(NETAMNT) NETAMNT,NULL SUPPLIER,DIVISION_NAME,B.MCODE,'A' FLG FROM #REPDATA A INNER JOIN MENUITEM B ON A.MGROUP = B.MCODE
				GROUP BY B.DESCA,B.MCODE,DIVISION_NAME
				UNION ALL
				SELECT NULL CODE,'TOTAL >>' MAINGROUP,NULL BC,NULL UNIT, SUM(SALESQTY)SQTY,SUM(RETURNQTY)RQTY,SUM(NETQTY)NETQTY, SUM(TOTVALUE) TOTVALUE, SUM(DISCOUNT)DISCOUNT, SUM(SCHARGE)SCHARGE, SUM(NETSALE) NETSALE, SUM(TAXABLE)TAXABLE,
				SUM(NONTAXABLE)NONTAXABLE,SUM(VAMNT) VAMNT,SUM(NETAMNT) NETAMNT,NULL SUPPLIER,NULL DIVISION_NAME,NULL MCODE,'B' FLG FROM #REPDATA A
			) A ORDER BY FLG,MAINGROUP

		ELSE IF @WISE = 'MCAT'
			SELECT * FROM 
			(
				SELECT NULL CODE,A.MCAT,NULL BC,NULL UNIT,SUM(SALESQTY)SQTY,SUM(RETURNQTY)RQTY,SUM(NETQTY)NETQTY, SUM(TOTVALUE) TOTVALUE, SUM(DISCOUNT)DISCOUNT, SUM(SCHARGE)SCHARGE, SUM(NETSALE) NETSALE, SUM(TAXABLE)TAXABLE,
				SUM(NONTAXABLE)NONTAXABLE,SUM(VAMNT) VAMNT,SUM(NETAMNT) NETAMNT,'A' FLG FROM #REPDATA A 
				GROUP BY A.MCAT	
				UNION ALL
				SELECT NULL CODE,'TOTAL >>' MCAT,NULL BC,NULL UNIT,SUM(SALESQTY)SQTY,SUM(RETURNQTY)RQTY,SUM(NETQTY)NETQTY, SUM(TOTVALUE) TOTVALUE, SUM(DISCOUNT)DISCOUNT, SUM(SCHARGE)SCHARGE, SUM(NETSALE) NETSALE, SUM(TAXABLE)TAXABLE,
				SUM(NONTAXABLE)NONTAXABLE,SUM(VAMNT) VAMNT,SUM(NETAMNT) NETAMNT,'B' FLG FROM #REPDATA A 
			) A ORDER BY FLG,MCAT

		ELSE IF @WISE = 'PTYPE'
			SELECT * FROM 
			(
				SELECT NULL CODE,ISNULL(X.PTYPENAME,'N/A')PTYPENAME,NULL BC,NULL UNIT,SUM(SALESQTY)SQTY,SUM(RETURNQTY)RQTY,SUM(NETQTY)NETQTY, SUM(TOTVALUE) TOTVALUE, SUM(DISCOUNT)DISCOUNT, SUM(SCHARGE)SCHARGE, SUM(NETSALE) NETSALE, SUM(TAXABLE)TAXABLE,
				SUM(NONTAXABLE)NONTAXABLE,SUM(VAMNT) VAMNT,SUM(NETAMNT) NETAMNT,'A' FLG FROM #REPDATA A LEFT JOIN PTYPE X ON ISNULL(A.PTYPE,0) = X.PTYPEID
				GROUP BY ISNULL(X.PTYPENAME,'N/A')
				UNION ALL
				SELECT NULL CODE,'TOTAL >>' PTYPENAME,NULL BC,NULL UNIT,SUM(SALESQTY)SQTY,SUM(RETURNQTY)RQTY,SUM(NETQTY)NETQTY, SUM(TOTVALUE) TOTVALUE, SUM(DISCOUNT)DISCOUNT, SUM(SCHARGE)SCHARGE, SUM(NETSALE) NETSALE, SUM(TAXABLE)TAXABLE,
				SUM(NONTAXABLE)NONTAXABLE,SUM(VAMNT) VAMNT,SUM(NETAMNT) NETAMNT,'B' FLG FROM #REPDATA A 
			)  A ORDER BY PTYPENAME
	END
ELSE
	--PREPARING TREE
	BEGIN
		IF OBJECT_ID('TEMPDB..#RESULT') IS NOT NULL DROP TABLE #RESULT	
		
		SELECT BC,UNIT,SUM(SALESQTY)SQTY,SUM(RETURNQTY)RQTY,SUM(NETQTY)NETQTY,SUM(TOTVALUE) TOTVALUE, SUM(DISCOUNT)DISCOUNT, SUM(SCHARGE)SCHARGE, SUM(NETSALE) NETSALE, SUM(TAXABLE)TAXABLE,
		SUM(NONTAXABLE)NONTAXABLE,SUM(VAMNT) VAMNT,SUM(NETAMNT) NETAMNT,X.ACNAME SUPPLIER,DIVISION_NAME,MCODE MC INTO #RESULT FROM #REPDATA A LEFT JOIN RMD_ACLIST X ON A.SUPCODE = X.ACID
		GROUP BY BC,MENUCODE,DESCA,MCODE,UNIT,DIVISION_NAME,X.ACNAME
		
		IF OBJECT_ID('TEMPDB..#TREE') IS NOT NULL DROP TABLE #TREE
		
		SELECT CASE WHEN A.TYPE='G' THEN '-' ELSE NULL END AS SYMBOL, A.DESCRIPTION,A.CODE MENUCODE,A.LEVEL,B.*,X.PARENT,A.ID,A.TYPE,A.MCODE 	
		INTO #TREE 
		FROM TreeExpand_function ('MI','PRODUCT LIST',0) AS A LEFT JOIN #RESULT B ON A.MCODE = B.MC 
		LEFT JOIN MENUITEM X ON A.MCODE = X.MCODE
		
		--SUMMING GROUP
		DECLARE @LVL INT
		select @LVL=MAX(LEVEL) from #TREE 
		PRINT @LVL

		WHILE @lvl > 0
			BEGIN
				UPDATE A SET A.SQTY=B.SQTY,A.RQTY = B.RQTY,A.NETQTY = B.NETQTY,A.TOTVALUE = B.TOTVALUE,A.DISCOUNT = B.DISCOUNT,A.SCHARGE = B.SCHARGE,
				A.NETSALE = B.NETSALE,A.TAXABLE = B.TAXABLE,A.NONTAXABLE = B.NONTAXABLE,A.VAMNT = B.VAMNT,A.NETAMNT = B.NETAMNT
				FROM #TREE A INNER JOIN 
				(select PARENT,ISNULL(SUM(SQTY),0)SQTY,ISNULL(SUM(RQTY),0) RQTY,ISNULL(SUM(NETQTY),0) NETQTY,ISNULL(SUM(TOTVALUE),0) TOTVALUE,
				ISNULL(SUM(DISCOUNT),0) DISCOUNT,
				ISNULL(SUM(SCHARGE),0) SCHARGE, ISNULL(SUM(NETSALE),0) NETSALE,ISNULL(SUM(TAXABLE),0) TAXABLE,ISNULL(SUM(NONTAXABLE),0) NONTAXABLE,ISNULL(SUM(VAMNT),0) VAMNT,
				ISNULL(SUM(NETAMNT),0) NETAMNT 
				FROM #TREE where level= @lvl
				GROUP BY PARENT) B on A.MCODE =B.PARENT
				SET @lvl = @lvl - 1;
			END

		--DISPLAYING RESULT
		------------------
		SELECT SYMBOL,DESCRIPTION DESCA,MENUCODE,BC,UNIT,SQTY,RQTY,NETQTY,TOTVALUE,DISCOUNT,SCHARGE,NETSALE,TAXABLE,NONTAXABLE,
		VAMNT,NETAMNT,SUPPLIER,DIVISION_NAME,MCODE,TYPE FROM #TREE
		WHERE SQTY <> 0 or RQTY <>0 or NETQTY <>0 or TOTVALUE <>0 or DISCOUNT <> 0 or SCHARGE <> 0 or NETSALE <> 0 or TAXABLE <> 0 or NONTAXABLE <> 0 OR VAMNT <> 0 OR NETAMNT <> 0 
		ORDER BY ID

	END
	
IF OBJECT_ID('TEMPDB..#REPDATA') is not null drop table #REPDATA
IF OBJECT_ID('TEMPDB..#TREE') IS NOT NULL DROP TABLE #TREE
IF OBJECT_ID('TEMPDB..#RESULT') IS NOT NULL DROP TABLE #RESULT	
IF OBJECT_ID('TEMPDB..#MENUITEM') is not null drop table #MENUITEM		

set nocount off
