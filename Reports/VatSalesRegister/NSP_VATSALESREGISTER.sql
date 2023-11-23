CREATE OR ALTER     PROCEDURE [dbo].[NSP_VATSALESREGISTER]
	--DECLARE
	@DATE1 VARCHAR(25),
	@DATE2 VARCHAR(25),
	@DIV AS VARCHAR(25) = '%',
	@V1 AS VARCHAR(2) = '%',
	@V2 AS VARCHAR(2) = '%',
	@REPMODE AS VARCHAR(25) = '%'

AS

--SELECT @DATE1 = '07-16-2023', @DATE2 = '07-15-2024', @DIV = '%', @V1  = 'SI', @V2 ='CN', @REPMODE = 0

set nocount on


DECLARE @TMRVCHRNO AS TINYINT
SELECT @TMRVCHRNO = TERMINALVCHR  FROM SETTING

IF @REPMODE = 0
	BEGIN
		IF OBJECT_ID('TEMPDB..#REPORT') is not null drop table #REPORT
		SELECT * INTO #REPORT FROM
		(
			SELECT TRNDATE, TM.Stamp, BSDATE, VCHRNO,
			COALESCE(NULLIF(TM.BILLTO,''), CP.CUSTNAME, M.FNAME, A.ACNAME,CONCAT(dbo.fnPascalCase(TM.TRNMODE), ' Sales')) PARTICULARS,
			COALESCE(NULLIF(TM.BILLTOTEL,''), CP.PANNO, M.PANNO, A.VATNO,'') VATNO,
			IIF (VoucherType IN ('TI', @V1), (TAXABLE+NONTAXABLE+DCAMNT), (TAXABLE+NONTAXABLE+DCAMNT)*-1) GROSSSALESAMOUNT,
			IIF (VoucherType IN ('TI', @V1), (TAXABLE+NONTAXABLE+DCAMNT+VATAMNT), (TAXABLE+NONTAXABLE+DCAMNT+VATAMNT)*-1) SALESAMOUNT,
			IIF (VoucherType IN ('TI', @V1), (NONTAXABLE), (NONTAXABLE)*-1) NONTAXABLE,	
			NULL EXPORTSALES,
			IIF (VoucherType IN ('TI', @V1), (DCAMNT), (DCAMNT)*-1) DISCOUNT,
			IIF (VoucherType IN ('TI', @V1), (TAXABLE), (TAXABLE)*-1) TAXABLE,
			IIF (VoucherType IN ('TI', @V1), (VATAMNT), (VATAMNT)*-1) VATAMNT, ISNULL(VNUM,VCHRNO) VNO,DIVISION,
			IIF (VoucherType IN ('TI', @V1), REFBILL, VNUM) XVNO 
			FROM SALES_TRNMAIN TM 
			LEFT JOIN CustomerProfile CP ON TM.RECEIVEBY = CP.CUSTID
			LEFT JOIN MEMBERSHIP M ON M.MEMID = TM.MEMBERNO
			LEFT JOIN RMD_ACLIST A ON A.ACID = TM.PARAC WHERE VoucherType IN ('TI','RE', @V1)
			AND (TRNDATE > = @DATE1 AND TRNDATE < = @DATE2) AND DIVISION LIKE @DIV
			/*
			UNION ALL
			SELECT TRNDATE,BSDATE,
			'SI' + CAST(MIN(CAST(SUBSTRING(VNUM, 3,LEN(VNUM)) AS INTEGER)) AS VARCHAR) + ' - ' + 'SI' + CAST(MAX(CAST(SUBSTRING(VNUM, 3,LEN(VNUM)) AS INTEGER)) AS VARCHAR) AS VOUCHER,
			'Abb. Tax Invoice' as Particular,NULL [VATNO],SUM(GROSSSALE) GROSSSALE, SUM(NETSALE) NETSALE,SUM(NONTAXABLE) AS NONTAXABLE,NULL EXPORTSALES,
			SUM(DCAMNT) DISCOUNT, SUM(TAXABLE) AS TAXABLE, SUM(VAT) AS VAT,'SI0000' VNO,DIVISION,'SI1' XVNO
			FROM 
			(
				SELECT VCHRNO,TRNDATE, BSDATE,TOTAMNT,DCAMNT,(TAXABLE+NONTAXABLE+DCAMNT) GROSSSALE, (TAXABLE+NONTAXABLE+DCAMNT+VATAMNT) AS NETSALE, TAXABLE,VATAMNT AS VAT, 
				NONTAXABLE,NETAMNT,DIVISION,ISNULL(VNUM,VCHRNO) VNUM FROM RMD_TRNMAIN WHERE VoucherType = @V1  AND (TRNDATE >= @DATE1 AND TRNDATE < =  @DATE2) AND DIVISION LIKE @DIV
			) X GROUP BY TRNDATE,BSDATE,DIVISION
			*/
			UNION ALL

			SELECT TRNDATE, TM.Stamp, BSDATE, VCHRNO,
			COALESCE(NULLIF(TM.BILLTO,''), CP.CUSTNAME, M.FNAME, A.ACNAME,'') PARTICULARS,
			COALESCE(NULLIF(TM.BILLTOTEL,''), CP.PANNO, M.PANNO, A.VATNO,'') VATNO,
			(TAXABLE+NONTAXABLE+DCAMNT)*-1 GROSSSALES,
			(TAXABLE+NONTAXABLE+DCAMNT+VATAMNT)*-1 SALESAMOUNT,	(NONTAXABLE)*-1 NONTAXABLE,	NULL EXPORTSALES,
			DCAMNT *-1 DISCOUNT, (TAXABLE)*-1 TAXABLE,(VATAMNT)*-1 VATAMNT, ISNULL(VNUM,VCHRNO) VNO,DIVISION, VNUM XVNO 
			FROM RMD_TRNMAIN TM
			LEFT JOIN CustomerProfile CP ON TM.RECEIVEBY = CP.CUSTID
			LEFT JOIN MEMBERSHIP M ON M.MEMID = TM.MEMBERNO
			LEFT JOIN RMD_ACLIST A ON TM.PARAC = A.ACID WHERE VoucherType = @V2
			AND (TRNDATE > = @DATE1 AND TRNDATE < = @DATE2) AND DIVISION LIKE @DIV
		) A

		SELECT TRNDATE,BSDATE,VCHRNO,PARTICULARS PARTICULAR,VATNO, 
		CONVERT(NUMERIC(18,2),GROSSSALESAMOUNT) GROSSSALESAMOUNT, 
		CONVERT(NUMERIC(18,2),SALESAMOUNT) SALESAMOUNT,
		CONVERT(NUMERIC(18,2),NONTAXABLE) NONTAXABLE,
		CONVERT(NUMERIC(18,2),EXPORTSALES) EXPORTSALES,
		CONVERT(NUMERIC(18,2),DISCOUNT) DISCOUNT,
		CONVERT(NUMERIC(18,2),TAXABLE)TAXABLE,
		CONVERT(NUMERIC(18,2),VATAMNT) VATAMNT,VNO,DIVISION   FROM 
		(
			SELECT TRNDATE, STAMP, RIGHT(BSDATE,4) + '.' + SUBSTRING(BSDATE,4,2) +'.'+LEFT(BSDATE,2) BSDATE,VCHRNO,PARTICULARS,VATNO,GROSSSALESAMOUNT, SALESAMOUNT,NONTAXABLE,EXPORTSALES,DISCOUNT,TAXABLE,VATAMNT,VNO,DIVISION,'A'FLG,XVNO FROM #REPORT
			UNION ALL
			SELECT NULL, NULL, NULL,NULL,'TOTAL >>',NULL,SUM(GROSSSALESAMOUNT),SUM(SALESAMOUNT),SUM(NONTAXABLE),SUM(EXPORTSALES),SUM(DISCOUNT),SUM(TAXABLE),SUM(VATAMNT),'ZZ00000001' VNO,'XXXXXXXXX' DIVISION,'B' FLG,'ZZ00000001' XVNO FROM #REPORT
		) A ORDER BY FLG,trndate, stamp, left(XVNO,2)DESC,CAST(SUBSTRING(A.XVNO,3,LEN(A.XVNO)) AS NUMERIC)
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
				NONTAXABLE,NETAMNT,DIVISION,ISNULL(VNUM,VCHRNO) VNUM FROM RMD_TRNMAIN WHERE VoucherType = @V1 AND (TRNDATE >= @DATE1 AND TRNDATE < =  @DATE2) AND DIVISION LIKE @DIV
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
			SELECT TRNDATE,RIGHT(BSDATE,4) + '.' + SUBSTRING(BSDATE,4,2) +'.'+LEFT(BSDATE,2) BSDATE,VOUCHER,PARTICULAR,VATNO,GROSSSALESAMOUNT,SALESAMOUNT,NONTAXABLE,EXPORTSALES,DISCOUNT,TAXABLE,VAT VATAMNT,VNO,DIVISION,'A'FLG,XVNO FROM #REPORT1
			UNION ALL
			SELECT NULL,NULL,NULL,'TOTAL >>',NULL, SUM(GROSSSALESAMOUNT),SUM(SALESAMOUNT),SUM(NONTAXABLE),SUM(EXPORTSALES),SUM(DISCOUNT),SUM(TAXABLE),SUM(VAT),'ZZ00000001' VNO,'XXXXXXXXX' DIVISION,'B' FLG,'ZZ00000001' XVNO FROM #REPORT1
		) A ORDER BY FLG,trndate,left(XVNO,2)DESC,CAST(SUBSTRING(A.XVNO,3,LEN(A.XVNO)) AS NUMERIC)
END

