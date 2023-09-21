CREATE OR ALTER     PROCEDURE [dbo].[NSP_VATSALESREGISTER_NEWFORMAT]
	--DECLARE
	@DATE1 VARCHAR(25),
	@DATE2 VARCHAR(25),
	@DIV AS VARCHAR(25) = '%',
	@V1 AS VARCHAR(2) = '%',
	@V2 AS VARCHAR(2) = '%',
	@REPMODE AS VARCHAR(25) = '%'

AS

--SELECT @DATE1 = '07-16-2020', @DATE2 = '07-15-2021', @DIV = 'MMD', @V1  = 'SI', @V2 ='CN', @REPMODE = 0

set nocount on

--SET @REPMODE = 0
DECLARE @TMRVCHRNO AS TINYINT
SELECT @TMRVCHRNO = TERMINALVCHR  FROM SETTING

IF @REPMODE = 0
	BEGIN
		IF OBJECT_ID('TEMPDB..#REPORT') is not null drop table #REPORT
		SELECT * INTO #REPORT FROM
		(
			SELECT TM.TRNDATE, TM.BSDATE, TM.VCHRNO,
			COALESCE(NULLIF(TM.BILLTO,''), CP.CUSTNAME, M.FNAME, A.ACNAME,CONCAT(dbo.fnPascalCase(TM.TRNMODE), ' Sales')) PARTICULARS,
			COALESCE(NULLIF(TM.BILLTOTEL,''), CP.PANNO, M.PANNO, A.VATNO,'') VATNO,
			TP.ITEMDESC ItemName, TP.AltUnit UNIT,
			CASE WHEN TM.VoucherType IN ('SI', 'TI') THEN TP.AltQty ELSE TP.ALTQTY_IN * -1 END Quantity,
			CASE WHEN TM.VoucherType IN ('SI', 'TI') THEN (TP.TAXABLE + TP.NONTAXABLE + TP.DISCOUNT) ELSE ( TP.TAXABLE + TP.NONTAXABLE + TP.DISCOUNT)*-1 END GROSSSALESAMOUNT,
			CASE WHEN TM.VoucherType IN ('SI', 'TI') THEN (TP.TAXABLE + TP.NONTAXABLE + TP.VAT) ELSE (TP.TAXABLE + TP.NONTAXABLE + TP.VAT)*-1 END SALESAMOUNT,
			CASE WHEN TM.VoucherType IN ('SI', 'TI') THEN (TP.NONTAXABLE) ELSE (TP.NONTAXABLE)*-1 END NONTAXABLE,	
			NULL EXPORTSALES,
			CASE WHEN TM.VoucherType IN ('SI', 'TI') THEN (TP.DISCOUNT) ELSE (TP.DISCOUNT)*-1 END DISCOUNT,
			CASE WHEN TM.VoucherType IN ('SI', 'TI') THEN (TP.TAXABLE) ELSE (TP.TAXABLE)*-1 END TAXABLE,
			CASE WHEN TM.VoucherType IN ('SI', 'TI') THEN (TP.VAT) ELSE (TP.VAT)*-1 END VATAMNT, ISNULL(VNUM,LEFT(TM.VCHRNO, CHARINDEX('-',TM.VCHRNO)-1)) VNO,TM.DIVISION,
			CASE WHEN TM.VCHRNO LIKE 'RE%' THEN REFBILL ELSE VNUM END XVNO 
			FROM SALES_TRNMAIN TM JOIN SALES_TRNPROD TP ON TM.VCHRNO = TP.VCHRNO
			LEFT JOIN CustomerProfile CP ON TM.RECEIVEBY = CP.CUSTID
			LEFT JOIN MEMBERSHIP M ON M.MEMID = TM.MEMBERNO
			LEFT JOIN RMD_ACLIST A ON TM.PARAC = A.ACID WHERE TM.VoucherType IN ('SI','TI','RE')

			AND (TRNDATE > = @DATE1 AND TRNDATE < = @DATE2) AND TM.DIVISION LIKE @DIV
			/*
			UNION ALL
			SELECT TRNDATE,BSDATE,
			'SI' + CAST(MIN(CAST(SUBSTRING(VNUM, 3,LEN(VNUM)) AS INTEGER)) AS VARCHAR) + ' - ' + 'SI' + CAST(MAX(CAST(SUBSTRING(VNUM, 3,LEN(VNUM)) AS INTEGER)) AS VARCHAR) AS VOUCHER,
			'Abb. Tax Invoice' as Particular,NULL [VATNO], ITEMDESC Item, SUM(ALTQTY) Quantity, SUM(GROSSSALE) GROSSSALE, SUM(NETSALE) NETSALE,SUM(NONTAXABLE) AS NONTAXABLE,NULL EXPORTSALES,
			SUM(DISCOUNT) DISCOUNT, SUM(TAXABLE) AS TAXABLE, SUM(VAT) AS VAT,'SI0000' VNO,DIVISION,'SI1' XVNO
			FROM 
			(
				SELECT TM.VCHRNO,TM.TRNDATE, TM.BSDATE, TP.ITEMDESC, TP.AltQty, TP.AMOUNT, TP.DISCOUNT, (TP.TAXABLE + TP.NONTAXABLE + TP.DISCOUNT) GROSSSALE, 
				(TP.TAXABLE + TP.NONTAXABLE + TP.DISCOUNT + TP.VAT) AS NETSALE, TP.TAXABLE, TP.VAT, 
				TP.NONTAXABLE,TP.NETAMOUNT, TM.DIVISION,ISNULL(TM.VNUM,LEFT(TM.VCHRNO, CHARINDEX('-',TM.VCHRNO)-1)) VNUM 
				FROM RMD_TRNMAIN TM JOIN SALES_TRNPROD TP ON TM.VCHRNO = TP.VCHRNO 
				WHERE TM.VoucherType = @V1  AND (TRNDATE >= @DATE1 AND TRNDATE < =  @DATE2) AND TM.DIVISION LIKE @DIV
			) X GROUP BY TRNDATE,BSDATE,DIVISION, ITEMDESC
			*/
			UNION ALL
			SELECT TM.TRNDATE, TM.BSDATE, TM.VCHRNO,
			CASE WHEN TM.BILLTO = '' THEN CASE WHEN TM.TRNMODE = 'Cash' OR TM.TRNMODE = 'MixedMode' THEN 'Cash Sales' ELSE A.ACNAME END ELSE TM.BILLTO END  AS PARTICULARS,
			CASE WHEN TM.BILLTOTEL = '' THEN CASE WHEN TM.TRNMODE = 'Cash' OR TM.TRNMODE = 'MixedMode' THEN '' ELSE A.VATNO END ELSE TM.BILLTOTEL END  AS VATNO,
			TP.ITEMDESC ItemName, TP.ALTUNIT Unit, TP.ALTQTY_IN * -1 Quantity,
			(TP.TAXABLE + TP.NONTAXABLE + TP.DISCOUNT)*-1 GROSSSALES,
			(TP.TAXABLE + TP.NONTAXABLE + TP.DISCOUNT + TP.VAT)*-1 SALESAMOUNT,	(TP.NONTAXABLE)*-1 NONTAXABLE,	NULL EXPORTSALES,
			TP.DISCOUNT *-1 DISCOUNT, (TP.TAXABLE)*-1 TAXABLE, (TP.VAT)*-1 VATAMNT, ISNULL(TM.VNUM,LEFT(TM.VCHRNO, CHARINDEX('-',TM.VCHRNO)-1)) VNO, TM.DIVISION, TM.VNUM XVNO 
			FROM RMD_TRNMAIN TM JOIN SALES_TRNPROD TP ON TM.VCHRNO = TP.VCHRNO 
			LEFT JOIN RMD_ACLIST A ON TM.TRNAC = A.ACID WHERE TM.VoucherType = @V2
			AND (TM.TRNDATE > = @DATE1 AND TM.TRNDATE < = @DATE2) AND TM.DIVISION LIKE @DIV
		) A

		SELECT TRNDATE,RIGHT(BSDATE,4) + '.' + SUBSTRING(BSDATE,4,2) +'.'+LEFT(BSDATE,2) BSDATE,VCHRNO,PARTICULARS PARTICULAR,VATNO, ItemName, Unit, Quantity, 
		CONVERT(NUMERIC(18,2),GROSSSALESAMOUNT) GROSSSALESAMOUNT, 
		CONVERT(NUMERIC(18,2),SALESAMOUNT) SALESAMOUNT,
		CONVERT(NUMERIC(18,2),NONTAXABLE) NONTAXABLE,
		CONVERT(NUMERIC(18,2),TAXABLE)TAXABLE,
		CONVERT(NUMERIC(18,2),VATAMNT) VATAMNT,
		CONVERT(NUMERIC(18,2),EXPORTSALES) EXPORTSALES,
		NULL COUNTRY, NULL PragyapanPatraNo, NULL PragyapanPatraMiti,
		CONVERT(NUMERIC(18,2),DISCOUNT) DISCOUNT,
		VNO,DIVISION   FROM 
		(
			SELECT TRNDATE,BSDATE,VCHRNO,PARTICULARS,VATNO, ItemName, Unit, Quantity,GROSSSALESAMOUNT, SALESAMOUNT,NONTAXABLE,EXPORTSALES,DISCOUNT,TAXABLE,VATAMNT,VNO,DIVISION,'A'FLG,XVNO FROM #REPORT
			UNION ALL
			SELECT NULL,NULL,NULL,'TOTAL >>',NULL,NULL,NULL, NULL,SUM(GROSSSALESAMOUNT),SUM(SALESAMOUNT),SUM(NONTAXABLE),SUM(EXPORTSALES),SUM(DISCOUNT),SUM(TAXABLE),SUM(VATAMNT),'ZZ00000001' VNO,'XXXXXXXXX' DIVISION,'B' FLG,'ZZ00000001' XVNO FROM #REPORT
		) A ORDER BY FLG,trndate,left(XVNO,2)DESC,CAST(SUBSTRING(A.XVNO,3,LEN(A.XVNO)) AS NUMERIC)
	END

ELSE IF @REPMODE = 1
	BEGIN
		IF OBJECT_ID('TEMPDB..#REPORT1') is not null drop table #REPORT1
	
		SELECT * INTO #REPORT1 FROM
		(
			SELECT TRNDATE,BSDATE,
			'TI' + CAST(MIN(CAST(SUBSTRING(VNUM, 3,LEN(VNUM)) AS INTEGER)) AS VARCHAR) + ' - ' + 'TI' + CAST(MAX(CAST(SUBSTRING(VNUM, 3,LEN(VNUM)) AS INTEGER)) AS VARCHAR) AS VOUCHER,
			'Tax Invoice' as Particular,NULL [VATNO],
			SUM((TAXABLE+NONTAXABLE+DCAMNT)) GROSSSALESAMOUNT,
			SUM((TAXABLE+NONTAXABLE+DCAMNT+VATAMNT)) SALESAMOUNT,SUM(NONTAXABLE) NONTAXABLE,NULL EXPORTSALES, SUM(DCAMNT) DISCOUNT, SUM(TAXABLE) TAXABLE, SUM(VATAMNT) VAT,
			'TI0000' VNO,DIVISION,'TI1' XVNO FROM RMD_TRNMAIN WHERE VoucherType LIKE 'TI' AND (TRNDATE > = @DATE1 AND TRNDATE < = @DATE2) AND DIVISION LIKE @DIV
			GROUP BY TRNDATE,BSDATE,DIVISION
	
			UNION ALL

			SELECT TRNDATE,BSDATE,
			'RE' + CAST(MIN(CAST(SUBSTRING(VNUM, 3,LEN(VNUM)) AS INTEGER)) AS VARCHAR) + ' - ' + 'RE' + CAST(MAX(CAST(SUBSTRING(VNUM, 3,LEN(VNUM)) AS INTEGER)) AS VARCHAR) AS VOUCHER,
			'Tax Invoice' as Particular,NULL [VATNO],
			SUM((TAXABLE+NONTAXABLE+DCAMNT))*-1 GROSSSALESAMOUNT,
			SUM((TAXABLE+NONTAXABLE+DCAMNT+VATAMNT))*-1 SALESAMOUNT,SUM(NONTAXABLE)*-1 NONTAXABLE,NULL EXPORTSALES, SUM(DCAMNT)*-1 DISCOUNT,SUM(TAXABLE)*-1 TAXABLE,  SUM(VATAMNT)*-1 VAT,
			'TI0000' VNO,DIVISION,'TI1' XVNO FROM RMD_TRNMAIN WHERE VoucherType LIKE 'RE' AND (TRNDATE > = @DATE1 AND TRNDATE < = @DATE2) AND DIVISION LIKE @DIV
			GROUP BY TRNDATE,BSDATE,DIVISION
	
			UNION ALL

			SELECT TRNDATE,BSDATE,
			'SI' + CAST(MIN(CAST(SUBSTRING(VNUM, 3,LEN(VNUM)) AS INTEGER)) AS VARCHAR) + ' - ' + 'SI' + CAST(MAX(CAST(SUBSTRING(VNUM, 3,LEN(VNUM)) AS INTEGER)) AS VARCHAR) AS VOUCHER,
			'Abb. Tax Invoice' as Particular,NULL [VATNO], SUM(GROSSSALESAMOUNT) AS GROSSSALESAMOUNT, SUM(SALESAMOUNT) AS SALESAMOUNT,SUM(NONTAXABLE) AS NONTAXABLE,NULL EXPORTSALES,
			SUM(DCAMNT) DISCOUNT, SUM(TAXABLE) AS TAXABLE, SUM(VAT) AS VAT,'SI0000' VNO,DIVISION,'SI1' XVNO
			FROM 
			(
				SELECT VCHRNO,TRNDATE, BSDATE, TOTAMNT,DCAMNT,TAXABLE+NONTAXABLE+DCAMNT GROSSSALESAMOUNT, TAXABLE+NONTAXABLE+DCAMNT+VATAMNT SALESAMOUNT, TAXABLE,VATAMNT AS VAT, 
				NONTAXABLE,NETAMNT,DIVISION,ISNULL(VNUM,LEFT(VCHRNO, CHARINDEX('-',VCHRNO)-1)) VNUM FROM RMD_TRNMAIN WHERE VoucherType = @V1 AND (TRNDATE >= @DATE1 AND TRNDATE < =  @DATE2) AND DIVISION LIKE @DIV
			) X GROUP BY TRNDATE,BSDATE,DIVISION

			UNION ALL

			SELECT TRNDATE,BSDATE,
			'CN' + CAST(MIN(CAST(SUBSTRING(VNUM, 3,LEN(VNUM)) AS INTEGER)) AS VARCHAR) + ' - ' + 'CN' + CAST(MAX(CAST(SUBSTRING(VNUM, 3,LEN(VNUM)) AS INTEGER)) AS VARCHAR) AS VOUCHER,
			'Tax Invoice' as Particular,NULL [VATNO],
			SUM((TAXABLE+NONTAXABLE+DCAMNT))*-1 GROSSSALESAMOUNT,
			SUM((TAXABLE+NONTAXABLE+DCAMNT+VATAMNT))*-1 SALESAMOUNT,SUM(NONTAXABLE)*-1 NONTAXABLE, NULL EXPORTSALES, SUM(DCAMNT)*-1 DISCOUNT, SUM(TAXABLE)*-1 TAXABLE, SUM(VATAMNT)*-1 VAT,
			'CN0000' VNO,DIVISION,'CN1' XVNO FROM RMD_TRNMAIN WHERE VoucherType LIKE @V2 AND (TRNDATE > = @DATE1 AND TRNDATE < = @DATE2) AND DIVISION LIKE @DIV
			GROUP BY TRNDATE,BSDATE,DIVISION	
		) A

		SELECT TRNDATE,BSDATE,VOUCHER VCHRNO,PARTICULAR,VATNO,
		CONVERT(NUMERIC(18,2),GROSSSALESAMOUNT) GROSSSALESAMOUNT,
		CONVERT(NUMERIC(18,2),SALESAMOUNT) SALESAMOUNT,
		CONVERT(NUMERIC(18,2),NONTAXABLE) NONTAXABLE,
		CONVERT(NUMERIC(18,2),EXPORTSALES)EXPORTSALES,
		CONVERT(NUMERIC(18,2),DISCOUNT) DISCOUNT,
		CONVERT(NUMERIC(18,2),TAXABLE)TAXABLE,
		CONVERT(NUMERIC(18,2),VATAMNT) VATAMNT,VNO,DIVISION   FROM 
		(
			SELECT TRNDATE,BSDATE,VOUCHER,PARTICULAR,VATNO,GROSSSALESAMOUNT,SALESAMOUNT,NONTAXABLE,EXPORTSALES,DISCOUNT,TAXABLE,VAT VATAMNT,VNO,DIVISION,'A'FLG,XVNO FROM #REPORT1
			UNION ALL
			SELECT NULL,NULL,NULL,'TOTAL >>',NULL, SUM(GROSSSALESAMOUNT),SUM(SALESAMOUNT),SUM(NONTAXABLE),SUM(EXPORTSALES),SUM(DISCOUNT),SUM(TAXABLE),SUM(VAT),'ZZ00000001' VNO,'XXXXXXXXX' DIVISION,'B' FLG,'ZZ00000001' XVNO FROM #REPORT1
		) A ORDER BY FLG,trndate,left(XVNO,2)DESC,CAST(SUBSTRING(A.XVNO,3,LEN(A.XVNO)) AS NUMERIC)
END
