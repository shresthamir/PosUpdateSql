CREATE OR ALTER PROCEDURE [dbo].[NSP_KOTREPORT]
--DECLARE 
@TDATE1 VARCHAR(25),
@TDATE2 VARCHAR(25),
@WAITER VARCHAR(50)='%',
@TBLNAME VARCHAR(25) = '%',
@TBLGROUP VARCHAR(50) = '%',
@REPTYPE VARCHAR(20) = '%',
@KOTTYPE TINYINT = '100',
@DIV VARCHAR(3) = '%'
AS

/*
SET @TDATE1 = '9-01-2018'
SET @TDATE2 = '01-01-2025'
SET @REPTYPE = '%'
SET @KOTTYPE = 100
SET @WAITER = '%'
*/



IF @REPTYPE IN ('CANCELLED', 'CANCEL')
 	SET @REPTYPE = 'CANCEL%'

SELECT * FROM 
(
	SELECT DISTINCT UPPER(ISNULL(A.WAITERNAME,'N/A')) WAITER,NULL TABLENO, NULL KOTID,NULL KOTNO,NULL KOTTIME,NULL ITEMCODE, NULL ITEMDESCRIPTION, NULL QUANTITY, NULL UNIT,NULL REMARKS,NULL BILLED, NULL BILLNO, NULL TRANSFERKOT, NULL MERGEKOT, NULL SPLITKOT,
	NULL CANCELBY,NULL CANCELREMARKS, UPPER(A.WAITERNAME) WAITERNAME,'A' FLG,NULL ISBARITEM FROM KOTRECORD A 
	LEFT JOIN TABLELIST B ON A.TABLENO = B.TableNo 
	INNER JOIN MENUITEM X ON A.MCODE = X.MCODE 
	WHERE A.TRNDATE BETWEEN @TDATE1 AND @TDATE2 AND ISNULL(A.WAITERNAME,'') LIKE @WAITER AND ISNULL(B.LAYOUTNAME,'')  LIKE @TBLGROUP AND A.TABLENO LIKE @TBLNAME AND 
	((@KOTTYPE = 100 AND ISNULL(X.ISBARITEM,0)<15) OR (@KOTTYPE <> 100 AND ISNULL(X.ISBARITEM,0)= @KOTTYPE)) AND
	ISNULL(A.BILLED,'') LIKE @REPTYPE

	UNION ALL

	SELECT CONVERT(VARCHAR(10),A.TRNDATE,10),A.TABLENO,A.KOTID, A.KOT KOTNO,A.KOTTIME KOTTIME,X.MENUCODE ITEMCODE,X.DESCA ITEMDESCRIPTION,A.QUANTITY,UNIT,A.RMKS,
	A.BILLED, A.BILLNO, A.TRANSFERKOTID, A.MERGEKOTID, A.SPLITKOTID, A.CUSER,A.CREMARKS, UPPER(ISNULL(A.WAITERNAME,'N/A')) WAITERNAME,'B' FLG,X.ISBARITEM FROM KOTRECORD A 
	LEFT JOIN TABLELIST B ON A.TABLENO = B.TableNo 
	INNER JOIN MENUITEM X ON A.MCODE = X.MCODE 
	WHERE A.TRNDATE BETWEEN @TDATE1 AND @TDATE2 AND ISNULL(A.WAITERNAME,'') LIKE @WAITER AND ISNULL(B.LAYOUTNAME,'')  LIKE @TBLGROUP AND A.TABLENO LIKE @TBLNAME AND 
	((@KOTTYPE = 100 AND ISNULL(X.ISBARITEM,0)<15) OR (@KOTTYPE <> 100 AND ISNULL(X.ISBARITEM,0)= @KOTTYPE)) AND
	ISNULL(A.BILLED,'') LIKE @REPTYPE

	UNION ALL

	SELECT DISTINCT NULL,NULL TABLENO,NULL KOTID,NULL KOTNO,NULL KOTTIME,NULL ITEMCODE, NULL ITEMDESCRIPTION, NULL QUANTITY, NULL UNIT,NULL REMARKS,NULL BILLED, NULL BILLNO, NULL TRANSFERKOT, NULL MERGEKOT, NULL SPLITKOT,NULL CUSER,NULL CREMARKS,UPPER(ISNULL(A.WAITERNAME,'N/A')) WAITERNAME,'C' FLG,NULL MCAT FROM KOTRECORD A
	LEFT JOIN TABLELIST B ON A.TABLENO = B.TableNo 
	INNER JOIN MENUITEM X ON A.MCODE = X.MCODE
	WHERE A.TRNDATE BETWEEN @TDATE1 AND @TDATE2 AND ISNULL(A.WAITERNAME,'') LIKE @WAITER AND ISNULL(B.LAYOUTNAME,'')  LIKE @TBLGROUP AND A.TABLENO LIKE @TBLNAME AND
	((@KOTTYPE = 100 AND ISNULL(X.ISBARITEM,0)<15) OR (@KOTTYPE <> 100 AND ISNULL(X.ISBARITEM,0)= @KOTTYPE)) AND
	ISNULL(A.BILLED,'') LIKE @REPTYPE
) A ORDER BY ISNULL(A.WAITERNAME,'N/A'),FLG,KOTNO,kottime