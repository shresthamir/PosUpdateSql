CREATE OR ALTER PROCEDURE [dbo].[NSP_SALESBOOKREPORT]
--DECLARE
	@DATE1 DATETIME,
	@DATE2 DATETIME,
	@DIV varchar(10)='%',
	@VOUCHER_TYPE CHAR(2) = 'SI',
	@INCLUDE_RETURN TINYINT = 0,									--	0 Exclude Return   1 Include Return
	@REPORT_TYPE TINYINT = 0,										--  1 VOUCHER WISE  2 DAY WISE  3 MONTH WISE	
	@SHOWDETAL_REPORT TINYINT = 0,									--  0 SUMMARY REPORT  1 DETAIL REPORT
	@VCHR VARCHAR(25) = 'A',
	@PARTY VARCHAR(25) = '%',
	@SMAN VARCHAR(25) = '%',
	@INAD TINYINT = 0,												-- 0 ENGLISH DATE  1 NEPALI DATE
	@DISCOUNTEDSALES TINYINT = 0,									-- 0 No Discount Sales, 1 Discounted Sales, 2 Card Discount Sales
	@DISRATE NUMERIC(18,8) = 0,										-- Discount Rate
	@COUNTERSALES TINYINT = 0,										-- 0 ALL   1 COUNTER SALES  2 TABLE SALES  
	@SALESMANWISESUMMARY TINYINT = 0,
	@FYID VARCHAR(10)	
AS

--select  @DATE1='2023-07-17 00:00:00',@DATE2='2024-09-22 00:00:00' ,@VOUCHER_TYPE=N'SI',@INCLUDE_RETURN=0,@REPORT_TYPE=N'1',@SHOWDETAL_REPORT=N'0',@VCHR=N'A',@party=N'%',@sman=N'%',@inad=N'1',@DISCOUNTEDSALES=N'0',@DISRATE=N'0',@COUNTERSALES=N'0',@SALESMANWISESUMMARY=0,@FYID=N'80/81'

set nocount on
DECLARE @CUSTID VARCHAR(25)
SELECT @CUSTID = CUSTID FROM CustomerProfile WHERE CUSTACCOUNT = @PARTY
IF ISNULL(@CUSTID,'') = '' SET @CUSTID = @PARTY
DECLARE @V1 VARCHAR(2),@V2 VARCHAR(2),@V3 VARCHAR(2),@V4 VARCHAR(2),@V5 VARCHAR(2), @enableHotelModule BIT
IF @VOUCHER_TYPE = 'SI'
	BEGIN 
		SET @V1 = 'SI';SET @V2 = 'TI';SET @V3 = 'RE'
		IF @INCLUDE_RETURN = 1
			BEGIN
				SET @V4 = 'CN';SET @V5 = 'SR'
			END
		ELSE
			BEGIN
				SET @V4 = 'A~';SET @V5 = 'B~'
			END
	END
ELSE
	BEGIN
		SET @V1 = 'IC'; SET @V2 = 'A~'; SET @V3 = 'B~'; SET @V5 = 'C~'
		IF @INCLUDE_RETURN = 1
			SET @V4 = 'IR'
		ELSE
			SET @V4 = 'C~'		
	END

IF @DISCOUNTEDSALES = 1 AND @DISRATE = 0
	SET @DISRATE = 0.00001

DECLARE @BillRoomDetail TABLE(BillNo VARCHAR(25) NOT NULL PRIMARY KEY, RoomNo VARCHAR(100) NOT NULL)
SELECT @enableHotelModule = EnableHotelModule FROM SETTING
IF @enableHotelModule = 1
	INSERT INTO @BillRoomDetail
	SELECT M.VCHRNO,R.RoomNo FROM TRNMAIN M 
		JOIN HTL_BOOKING HB ON M.REFORDBILL = HB.BookingId 
		JOIN HTL_ROOM R ON HB.RoomId = R.RoomId
		WHERE M.DIVISION LIKE @DIV AND M.TRNDATE BETWEEN @DATE1 AND @DATE2

IF @SALESMANWISESUMMARY = 0
BEGIN	
	IF @REPORT_TYPE = 1		--VOUCHER WISE
		BEGIN
			IF OBJECT_ID('TEMPDB..#RMD_TRNMAIN') is not null drop table #RMD_TRNMAIN
			IF OBJECT_ID('TEMPDB..#TRNMAIN') is not null drop table #TRNMAIN

			SELECT A.TRNDATE,A.DIVISION,A.BSDATE, ISNULL(A.BILLTO,'') AS BILLTO,A.VCHRNO,A.CHALANNO,A.TRNMODE,A.TRNAC, A.TOTAMNT,A.DCAMNT,ISNULL(A.STAX,0) STAX,A.TAXABLE,A.NONTAXABLE,A.VATAMNT,A.NETAMNT,
			A.REMARKS,ISNULL(A.REFBILL,'')REFBILL,ISNULL(A.CUSTOMER_COUNT,0)PAXNO,ISNULL(A.VNUM,A.VCHRNO)VNUM,A.TRNTIME,A.TRNUSER, (A.DCAMNT * 100)/A.TOTAMNT DISRATE,A.CHOLDER,A.PHISCALID, A.VoucherType, BRD.RoomNo
			INTO #RMD_TRNMAIN FROM RMD_TRNMAIN A LEFT JOIN BILLTENDER B ON A.VCHRNO = B.VNO	
			LEFT JOIN @BillRoomDetail BRD ON BRD.BillNo = A.VCHRNO
			WHERE LEFT(VCHRNO,2) IN (@V1,@V2,@V3,@V4,@V5) AND DIVISION LIKE @DIV AND (TRNDATE >=@DATE1 AND TRNDATE <= @DATE2) 
			AND (@PARTY = '%' OR (A.TRNAC = @PARTY OR A.PARAC = @PARTY OR A.RECEIVEBY = @CUSTID)) AND ISNULL(A.SALESMANID, ISNULL(B.SALESMANID,'')) LIKE @SMAN 
			AND ((@COUNTERSALES = 0 AND ISNULL(RETTO,'') LIKE '%') OR (@COUNTERSALES = 1 AND ISNULL(RETTO,'') LIKE 'Counter Billing') OR (@COUNTERSALES = 2 AND ISNULL(RETTO,'') LIKE 'Table Billing'))

			SELECT A.TRNDATE,A.BSDATE, A.VCHRNO, CASE WHEN A.VCHRNO LIKE 'TI%' THEN CASE WHEN A.REFBILL <> '' THEN A.REFBILL ELSE A.CHALANNO END ELSE A.CHALANNO END CHALANNO, 
			CASE WHEN A.TRNMODE IN ('Cash','Complimentary') THEN CASE WHEN ISNULL(A.BILLTO,'') <> '' THEN A.BILLTO ELSE B.ACNAME END ELSE B.ACNAME END AS PARTY,A.TRNMODE,
			CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.TOTAMNT *-1 ELSE A.TOTAMNT END AS TOTAMNT,
			CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.DCAMNT *-1 ELSE A.DCAMNT END AS DCAMNT,CASE WHEN LEFT(A.VCHRNO,2) IN (@V3,@V4,@V5) THEN A.STAX *-1 ELSE A.STAX END AS STAX,
			CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN (A.TAXABLE + A.NONTAXABLE) *-1 ELSE (A.TAXABLE + A.NONTAXABLE) END AS NETSALE,
			CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.NONTAXABLE  * -1 ELSE A.NONTAXABLE END AS NONTAXABLE,
			CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.TAXABLE  * -1 ELSE A.TAXABLE END AS TAXABLE,
			CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.VATAMNT * -1 ELSE A.VATAMNT END AS VATAMNT,
			CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.NETAMNT * -1 ELSE A.NETAMNT END AS TOTAL,
			CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.PAXNO * -1 ELSE A.PAXNO END AS PAXNO,
			A.TRNTIME,A.TRNUSER,X.NAME DIVNAME,VNUM, A.DIVISION,A.PHISCALID, DP.NAME DeliveryAgent, SI.RecipientName, SI.RecipientMobile, SI.RecipientAddress,A.REMARKS, A.RoomNo
			INTO #TRNMAIN FROM  #RMD_TRNMAIN AS A 
			LEFT JOIN RMD_ACLIST B ON A.TRNAC = B.ACID LEFT JOIN DIVISION X ON A.DIVISION = X.INITIAL
			LEFT JOIN tblShippingInfo SI ON A.VCHRNO = SI.VCHRNO
			LEFT JOIN DeliveryPartners DP ON SI.DeliveryAgent = DP.ID 
			WHERE 
			(
				(@DISCOUNTEDSALES = 0 AND ABS(DISRATE)>=0 AND ISNULL(CHOLDER,'') LIKE '%') 
				OR 
				(
					(@DISCOUNTEDSALES = 1 AND ABS(DISRATE) >=@DISRATE AND ISNULL(CHOLDER,'') LIKE '%') 
					OR 
					(@DISCOUNTEDSALES = 2 AND DISRATE >=@DISRATE AND ISNULL(CHOLDER,'') = 'CARD DISCOUNT')
					OR
					(@DISCOUNTEDSALES = 3 AND A.TRNMODE = 'Complimentary')
				)
			)
			
			IF @SHOWDETAL_REPORT = 0		-- SUMMARY REPORT					
				SELECT * FROM 
				(
					SELECT A.TRNDATE,A.BSDATE,A.VCHRNO,A.CHALANNO,A.PARTY,A.TRNMODE,A.TOTAMNT,A.DCAMNT,A.STAX,A.NETSALE,A.NONTAXABLE,A.TAXABLE,A.VATAMNT,A.TOTAL,A.PAXNO,A.TRNTIME, A.TRNUSER,A.DIVNAME,A.VNUM,A.DIVISION,'A' FLG, DeliveryAgent, RecipientName, 
					RecipientMobile, RecipientAddress,A.REMARKS, A.RoomNo FROM #TRNMAIN A
					UNION ALL
					SELECT NULL TRNDATE,NULL BSDATE,NULL VCHRNO,NULL CHALANNO,'TOTAL >>' PARTY,NULL TRNMODE,SUM(A.TOTAMNT),SUM(A.DCAMNT),SUM(A.STAX),SUM(A.NETSALE),SUM(A.NONTAXABLE),SUM(A.TAXABLE),SUM(A.VATAMNT),SUM(A.TOTAL),SUM(PAXNO) PAXNO,NULL TRNTIME,NULL TRNUSER,
					NULL DIVISION,'ZZ9999999' VNO,NULL DIVID,'B' FLG, NULL, NULL, NULL, NULL ,NULL, NULL FROM #TRNMAIN A
				) A ORDER BY FLG, TRNDATE,left(VNUM,2),CAST(RIGHT(A.VNUM,len(A.VNUM)-2) as numeric)

			ELSE			-- DETAIL REPORT
				BEGIN

					IF OBJECT_ID('TEMPDB..#RMD_TRNPROD') is not null drop table #RMD_TRNPROD

					select NULL AS TRNDATE, '' AS BSDATE, '' AS VCHRNO, C.MENUCODE AS MENUCODE,CASE WHEN ISNULL(C.ISUNKNOWN,0) = 0 THEN C.DESCA ELSE A.MANUFACTURER END AS PRODUCT,
					A.UNIT, CASE WHEN LEFT(A.VCHRNO,2) IN ('PI','RE','CN','SR') THEN A.REALQTY_IN ELSE  A.REALQTY END AS QUANTITY,  A.RATE AS RATE, A.AMOUNT, 
					CASE WHEN(A.DISCOUNT =0) THEN NULL ELSE A.DISCOUNT END AS DISCOUNT,CASE WHEN(A.SERVICETAX =0) THEN NULL ELSE A.SERVICETAX END AS SERVICETAX, 
					A.TAXABLE,A.NONTAXABLE,CASE WHEN (A.VAT = 0) THEN NULL ELSE A.VAT END AS VAT,(A.TAXABLE+A.NONTAXABLE+A.VAT) NETAMNT,B.VNUM,A.DIVISION INTO #RMD_TRNPROD FROM RMD_SALESPROD A INNER JOIN
					#TRNMAIN B ON A.VCHRNO = B.VCHRNO AND A.DIVISION = B.DIVISION AND A.PHISCALID = B.PHISCALID INNER JOIN MENUITEM C ON A.MCODE = C.MCODE
			

					SELECT * FROM 
					(
						SELECT A.TRNDATE,A.BSDATE,A.VCHRNO,A.CHALANNO,A.PARTY,A.TRNMODE,X.QTY, NULL RATE,A.TOTAMNT,A.DCAMNT,A.STAX,A.NONTAXABLE,A.TAXABLE,A.VATAMNT,A.TOTAL,A.PAXNO,A.TRNTIME, A.TRNUSER,A.DIVNAME,A.VNUM,A.DIVISION,'A' FLG, A.RoomNo FROM #TRNMAIN A
						INNER JOIN (SELECT VNUM,DIVISION,SUM(CASE WHEN LEFT(VNUM,2) IN ('CN','RE') THEN QUANTITY*-1 ELSE QUANTITY END) QTY FROM #RMD_TRNPROD GROUP BY VNUM,DIVISION) X ON A.VNUM =X.VNUM AND A.DIVISION = X.DIVISION
						UNION ALL
						SELECT A.TRNDATE,A.BSDATE,A.VCHRNO,A.MENUCODE,A.PRODUCT,A.UNIT,A.QUANTITY,A.RATE,A.AMOUNT,A.DISCOUNT,A.SERVICETAX,A.NONTAXABLE,A.TAXABLE,A.VAT,A.NETAMNT,NULL PAXNO,NULL TRNTIME,NULL TRNUSER,NULL DIVISION,A.VNUM, NULL DIVID,'B' FLG, NULL 
						FROM #RMD_TRNPROD A

						UNION ALL
						SELECT NULL TRNDATE,NULL BSDATE,NULL VCHRNO,NULL CHALANNO,NULL PARTY,NULL TRNMODE,NULL QTY, NULL RATE,NULL TOTAMNT,NULL DCAMNT,NULL STAX,NULL NONTAXABLE,NULL TAXABLE,NULL VATAMNT,NULL TOTAL,NULL PAXNO,NULL TRNTIME, NULL TRNUSER,NULL DIVISION,
						A.VNUM,A.DIVISION DIVID,'C' FLG, NULL FROM #TRNMAIN A
						
						UNION ALL
						SELECT NULL TRNDATE,NULL BSDATE,NULL VCHRNO,NULL CHALANNO,'TOTAL >>' PARTY,NULL TRNMODE,SUM(QTY) QTY, NULL RATE,SUM(A.TOTAMNT)TOTAMNT,SUM(A.DCAMNT)DCAMNT,
						SUM(A.STAX) STAX,SUM(A.NONTAXABLE) NONTAXABLE,SUM(A.TAXABLE) TAXABLE,SUM(A.VATAMNT) VATAMMT,SUM(A.TOTAL) TOTAL,SUM(A.PAXNO) PAXNO, NULL TRNTIME, NULL TRNUSER,
						NULL DIVISION,'ZZ99999999'  VNUM,NULL DIVID,'D' FLG, NULL FROM 
						(
							SELECT A.TRNDATE,A.BSDATE,A.VCHRNO,A.CHALANNO,A.PARTY,A.TRNMODE,X.QTY, NULL RATE,A.TOTAMNT,A.DCAMNT,A.STAX,A.NONTAXABLE,A.TAXABLE,A.VATAMNT,A.TOTAL,A.PAXNO,A.TRNTIME, A.TRNUSER,A.DIVNAME,A.VNUM,A.DIVISION,'A' FLG FROM #TRNMAIN A
							INNER JOIN 
							(
								SELECT VNUM,DIVISION,SUM(CASE WHEN LEFT(VNUM,2) IN ('CN','RE') THEN QUANTITY*-1 ELSE QUANTITY END) QTY FROM #RMD_TRNPROD GROUP BY VNUM,DIVISION
							) X ON A.VNUM =X.VNUM AND A.DIVISION = X.DIVISION
						) A
					--#TRNMAIN A
					--INNER JOIN (SELECT VNUM,DIVISION,SUM(CASE WHEN LEFT(VNUM,2) IN ('CN','RE') THEN QUANTITY*-1 ELSE QUANTITY END) QTY FROM #RMD_TRNPROD GROUP BY VNUM,DIVISION) X 
					--ON A.VNUM =X.VNUM AND A.DIVISION = X.DIVISION
					) A ORDER BY LEFT(VNUM,2), CAST(RIGHT(VNUM,LEN(VNUM)-2) AS NUMERIC),FLG

				--DIVISION,

					IF OBJECT_ID('TEMPDB..#RMD_TRNPROD') is not null drop table #RMD_TRNPROD
				
				END

		END
	ELSE IF @REPORT_TYPE = 2		-- DAY WISE 		
		SELECT TRNDATE, BSDATE,SUM(TOTAMNT) AS TOTAMNT, SUM(DCAMNT) AS DCAMNT, SUM(STAX)STAX, SUM(NETAMNT) AS NETAMNT, SUM(NONTAXABLE) AS NONTAXABLE,SUM(TAXABLE) AS TAXABLE, SUM(VATAMNT) AS VATAMNT, SUM(TAMNT) AS TAMNT,SUM(CASH) AS CASH, SUM(CCARD) AS CCARD, 
		SUM(CREDIT) AS CREDIT,SUM(GVOUCHER) GVOUCHER,SUM(PREPAID) PREPAID,SUM(N_ONLINE) [ONLINE],SUM(SalesReturnVoucher) SalesReturnVoucher,SUM(PAXNO)PAXNO 
		FROM
		(
			SELECT A.TRNDATE,A.BSDATE, 
			CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.TOTAMNT *-1 ELSE A.TOTAMNT END AS TOTAMNT,
			CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.DCAMNT *-1 ELSE A.DCAMNT END AS DCAMNT,
			CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.STAX *-1 ELSE A.STAX END AS STAX,
			CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN (A.TAXABLE + A.NONTAXABLE)*-1 ELSE (A.TAXABLE + A.NONTAXABLE)  END AS NETAMNT,
			CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.NONTAXABLE  * -1 ELSE A.NONTAXABLE END AS NONTAXABLE,
			CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.TAXABLE  * -1 ELSE A.TAXABLE END AS TAXABLE,
			CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.VATAMNT * -1 ELSE A.VATAMNT END AS VATAMNT,
			CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.NETAMNT * -1 ELSE A.NETAMNT END AS TAMNT,
			CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN NETCASH ELSE
			CASE WHEN TRNMODE = 'CASH' THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT *-1 ELSE NETAMNT END ELSE null END END AS CASH,
			CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN NCREDITCARD ELSE
			CASE WHEN TRNMODE IN ('CREDITCARD', 'CREDIT CARD') THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT *-1 ELSE NETAMNT END ELSE null END END AS CCARD,
			CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN NCREDIT ELSE
			CASE WHEN (TRNMODE = 'CREDIT') THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT * -1 ELSE NETAMNT END ELSE null END END AS CREDIT,
			CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN NGVOUCHER ELSE
			CASE WHEN (TRNMODE = 'GIFTVOUCHER') THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT * -1 ELSE NETAMNT END ELSE null END END AS GVOUCHER,
			CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN NPREPAID ELSE
			CASE WHEN (TRNMODE = 'PREPAID') THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT * -1 ELSE NETAMNT END ELSE null END END AS PREPAID,
			CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN N_ONLINE ELSE
			CASE WHEN (TRNMODE IN ('ONLINE', 'ESEWA', 'FONEPAY', 'QR')) THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT * -1 ELSE NETAMNT END ELSE null END END AS N_ONLINE,
			CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN NSalesReturnVoucher ELSE
			CASE WHEN (TRNMODE = 'Sales Return Voucher') THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT * -1 ELSE NETAMNT END ELSE null END END AS [SalesReturnVoucher],	
			CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN A.PAXNO * -1 ELSE A.PAXNO END AS PAXNO,DIVISION			
			FROM 
			(
				SELECT A.TRNDATE,A.DIVISION,A.BSDATE, A.VCHRNO,A.TRNMODE,A.TOTAMNT,A.DCAMNT,A.TAXABLE,A.NONTAXABLE,A.VATAMNT,A.NETAMNT,ISNULL(A.STAX,0)STAX,B.NETCASH,B.NCREDIT,B.NCREDITCARD,
				B.NGVOUCHER,B.NPREPAID,B.N_ONLINE,B.NSalesReturnVoucher,ISNULL(A.CUSTOMER_COUNT,0)PAXNO,ISNULL(A.VNUM,A.VCHRNO)VNUM,(A.DCAMNT * 100)/A.TOTAMNT DISRATE,A.CHOLDER, a.VoucherType FROM RMD_TRNMAIN A
				LEFT JOIN BILLTENDER B ON A.VCHRNO = B.VNO AND A.DIVISION = B.DIV AND A.PhiscalID =B.PHISCALID WHERE 
				LEFT(A.VCHRNO,2) IN (@V1,@V2,@V3,@V4,@V5) AND A.DIVISION LIKE @DIV AND (A.TRNDATE >=@DATE1 AND TRNDATE <= @DATE2) AND (@PARTY = '%' OR (A.TRNAC = @PARTY OR A.PARAC = @PARTY OR A.RECEIVEBY = @CUSTID)) 
				AND ISNULL(A.SALESMANID, ISNULL(B.SALESMANID,'')) LIKE @SMAN 
				AND ((@COUNTERSALES = 0 AND ISNULL(RETTO,'') LIKE '%') OR (@COUNTERSALES = 1 AND ISNULL(RETTO,'') LIKE 'Counter Billing') OR (@COUNTERSALES = 2 AND ISNULL(RETTO,'') LIKE 'Table Billing'))
			) A
			WHERE ((@DISCOUNTEDSALES = 0 AND ABS(DISRATE)>=0 AND ISNULL(CHOLDER,'') LIKE '%') OR ((@DISCOUNTEDSALES = 1 AND ABS(DISRATE) >=@DISRATE AND ISNULL(CHOLDER,'') LIKE '%') OR (@DISCOUNTEDSALES = 2 AND DISRATE >=@DISRATE 
			AND ISNULL(CHOLDER,'') = 'CARD DISCOUNT') OR (@DISCOUNTEDSALES = 3 AND A.TRNMODE = 'Complimentary')))
		) AS Z GROUP BY TRNDATE, BSDATE
		ORDER BY TRNDATE
			
	ELSE IF @REPORT_TYPE = 3				-- MONTH WISE
		
		BEGIN
			DECLARE @BDATE DATETIME; DECLARE @EDATE DATETIME;DECLARE @BDATE_BS VARCHAR(25); DECLARE @EDATE_BS VARCHAR(25)
			--SELECT @BDATE = FBDATE,@EDATE = FEDATE,@BDATE_BS = FBDATE_BS,@EDATE_BS = FEDATE_BS FROM COMPANY
			SELECT @BDATE = BeginDate,@EDATE = EndDate,@BDATE_BS = M1.MITI,@EDATE_BS = M2.MITI FROM PhiscalYear F 
				JOIN DATEMITI M1 ON F.BeginDate = M1.AD
				JOIN DATEMITI M2 ON F.EndDate = M2.AD
				WHERE PhiscalID = @FYID
					
			IF @INAD = 1	-- REPORT IN ENGLISH DATE				
				--SELECT * FROM DBO.GETMONTHLIST('01-01-2017','01-01-2018')

				SELECT  B.MNAME PARTICULARS,SUM(TOTAMNT) AS TOTAMNT, SUM(DCAMNT) AS DCAMNT,SUM(STAX)STAX, SUM(NETAMNT) AS NETAMNT, SUM(NONTAXABLE) AS NONTAXABLE, SUM(TAXABLE) AS TAXABLE, SUM(VATAMNT) AS VATAMNT, SUM(TAMNT) AS TAMNT,SUM(CASH) AS CASH
				, SUM(CCARD) AS CCARD, SUM(CREDIT) AS CREDIT,SUM(GVOUCHER) GVOUCHER,SUM(PREPAID) OTHERS,SUM([N_ONLINE])[ONLINE],SUM(SalesReturnVoucher) SalesReturnVoucher, SUM(PAXNO)PAXNO, ISNULL(MON,B.ID) MON,ISNULL(YER,B.YNAME)YER 
				FROM DBO.GETMONTHLIST(@BDATE,@EDATE) B LEFT JOIN 
				(
					SELECT * FROM 
					(
						SELECT CAST(DATEPART(m,A.TRNDATE) AS NUMERIC) AS MON, CAST(DATEPART(yy,A.TRNDATE) AS NUMERIC) AS YER, 
						CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.TOTAMNT *-1 ELSE A.TOTAMNT END AS TOTAMNT,
						CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.DCAMNT *-1 ELSE A.DCAMNT END AS DCAMNT,
						CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.STAX *-1 ELSE A.STAX END AS STAX,
						CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN (A.TAXABLE + A.NONTAXABLE)*-1 ELSE (A.TAXABLE + A.NONTAXABLE)  END AS NETAMNT,
						CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.NONTAXABLE  * -1 ELSE A.NONTAXABLE END AS NONTAXABLE,
						CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.TAXABLE  * -1 ELSE A.TAXABLE END AS TAXABLE,
						CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.VATAMNT * -1 ELSE A.VATAMNT END AS VATAMNT,
						CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.NETAMNT * -1 ELSE A.NETAMNT END AS TAMNT,
						CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN NETCASH ELSE 
						CASE WHEN (TRNMODE = 'CASH') THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT *-1 ELSE NETAMNT END ELSE null END END AS CASH,
						CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN NCREDITCARD ELSE
						CASE WHEN TRNMODE IN ('CREDITCARD', 'CREDIT CARD') THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT *-1 ELSE NETAMNT END ELSE null END END AS CCARD,
						CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN NCREDIT ELSE
						CASE WHEN (TRNMODE = 'CREDIT') THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT * -1 ELSE NETAMNT END ELSE null END END AS CREDIT,
						CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN NGVOUCHER ELSE		
						CASE WHEN (TRNMODE = 'GIFTVOUCHER') THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT * -1 ELSE NETAMNT END ELSE null END END AS GVOUCHER,
						CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN NPREPAID ELSE
						CASE WHEN (TRNMODE = 'PREPAID') THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT * -1 ELSE NETAMNT END ELSE null END END AS PREPAID,
						CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN N_ONLINE ELSE
						CASE WHEN (TRNMODE IN ('ONLINE', 'ESEWA', 'FONEPAY', 'QR')) THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT * -1 ELSE NETAMNT END ELSE null END END AS N_ONLINE,				
						CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN NSalesReturnVoucher ELSE
						CASE WHEN (TRNMODE = 'Sales Return Voucher') THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT * -1 ELSE NETAMNT END ELSE null END END AS [SalesReturnVoucher],	
						CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN A.PAXNO * -1 ELSE A.PAXNO END AS PAXNO,DIVISION			
						FROM 
						(
							SELECT A.TRNDATE,A.DIVISION,A.BSDATE, A.VCHRNO,A.TRNMODE,A.TOTAMNT,A.DCAMNT,A.TAXABLE,A.NONTAXABLE,A.VATAMNT,A.NETAMNT,A.STAX,B.NETCASH,B.NCREDIT,B.NCREDITCARD,
							B.NGVOUCHER,B.NPREPAID,B.N_ONLINE,B.NSalesReturnVoucher, ISNULL(A.CUSTOMER_COUNT,0)PAXNO,ISNULL(A.VNUM,A.VCHRNO)VNUM,(A.DCAMNT * 100)/A.TOTAMNT DISRATE,A.CHOLDER, A.VoucherType FROM RMD_TRNMAIN A
							LEFT JOIN BILLTENDER B ON A.VCHRNO = B.VNO AND A.DIVISION = B.DIV AND A.PhiscalID =B.PHISCALID WHERE 
							LEFT(A.VCHRNO,2) IN (@V1,@V2,@V3,@V4,@V5) AND A.DIVISION LIKE @DIV AND (A.TRNDATE >=@DATE1 AND TRNDATE <= @DATE2) AND (@PARTY = '%' OR (A.TRNAC = @PARTY OR A.PARAC = @PARTY OR A.RECEIVEBY = @CUSTID)) 
							AND ISNULL(A.SALESMANID, ISNULL(B.SALESMANID,'')) LIKE @SMAN 
							AND ((@COUNTERSALES = 0 AND ISNULL(RETTO,'') LIKE '%') OR (@COUNTERSALES = 1 AND ISNULL(RETTO,'') LIKE 'Counter Billing') OR (@COUNTERSALES = 2 AND ISNULL(RETTO,'') LIKE 'Table Billing'))
						) A
						WHERE ((@DISCOUNTEDSALES = 0 AND ABS(DISRATE)>=0 AND ISNULL(CHOLDER,'') LIKE '%') OR ((@DISCOUNTEDSALES = 1 AND ABS(DISRATE) >=@DISRATE AND ISNULL(CHOLDER,'') LIKE '%') 
						OR (@DISCOUNTEDSALES = 2 AND DISRATE >=@DISRATE AND ISNULL(CHOLDER,'') = 'CARD DISCOUNT') OR (@DISCOUNTEDSALES = 3 AND A.TRNMODE = 'Complimentary')))
					) AS Z 
				) A ON A.MON = B.ID AND A.YER = B.YNAME GROUP BY B.MNAME, ISNULL(MON,B.ID),ISNULL(YER,B.YNAME)  ORDER BY  ISNULL(YER,B.YNAME),ISNULL(MON,B.ID)
			
			ELSE	-- REPORT IN NEPALI MONTH			
				SELECT  B.MNAME PARTICULARS,SUM(TOTAMNT) AS TOTAMNT, SUM(DCAMNT) AS DCAMNT,SUM(STAX)STAX, SUM(NETAMNT) AS NETAMNT, SUM(NONTAXABLE) AS NONTAXABLE, SUM(TAXABLE) AS TAXABLE, SUM(VATAMNT) AS VATAMNT, SUM(TAMNT) AS TAMNT,SUM(CASH) AS CASH
				, SUM(CCARD) AS CCARD, SUM(CREDIT) AS CREDIT,SUM(GVOUCHER) GVOUCHER,SUM(PREPAID) OTHERS,SUM([ONLINE])[ONLINE],SUM(SalesReturnVoucher) SalesReturnVoucher,SUM(PAXNO)PAXNO,ISNULL(MON,B.ID) MON,ISNULL(YER,B.YNAME)YER
				FROM DBO.GETNEPALIMONTHLIST(@BDATE_BS,@EDATE_BS) B LEFT JOIN 
				(
					SELECT * FROM
					(
						SELECT CAST(RIGHT(LEFT(BSDATE,5),2) AS NUMERIC) AS MON, CAST(RIGHT(BSDATE,4) AS NUMERIC) AS YER,  
						CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.TOTAMNT *-1 ELSE A.TOTAMNT END AS TOTAMNT,
						CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.DCAMNT *-1 ELSE A.DCAMNT END AS DCAMNT,
						CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.STAX *-1 ELSE A.STAX END AS STAX,
						CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN (A.TAXABLE + A.NONTAXABLE)*-1 ELSE (A.TAXABLE + A.NONTAXABLE)  END AS NETAMNT,
						CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.NONTAXABLE  * -1 ELSE A.NONTAXABLE END AS NONTAXABLE,
						CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.TAXABLE  * -1 ELSE A.TAXABLE END AS TAXABLE,
						CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.VATAMNT * -1 ELSE A.VATAMNT END AS VATAMNT,
						CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.NETAMNT * -1 ELSE A.NETAMNT END AS TAMNT,
						CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN NETCASH ELSE 
						CASE WHEN (TRNMODE = 'CASH') THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT *-1 ELSE NETAMNT END ELSE null END END AS CASH,
						CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN NCREDITCARD ELSE
						CASE WHEN TRNMODE IN ('CREDITCARD', 'CREDIT CARD') THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT *-1 ELSE NETAMNT END ELSE null END END AS CCARD,
						CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN NCREDIT ELSE
						CASE WHEN (TRNMODE = 'CREDIT') THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT * -1 ELSE NETAMNT END ELSE null END END AS CREDIT,
						CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN NGVOUCHER ELSE
						CASE WHEN (TRNMODE = 'GIFTVOUCHER') THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT * -1 ELSE NETAMNT END ELSE null END END AS GVOUCHER,
						CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN NPREPAID ELSE
						CASE WHEN (TRNMODE = 'PREPAID') THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT * -1 ELSE NETAMNT END ELSE null END END AS PREPAID,
						CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN N_ONLINE ELSE
						CASE WHEN (TRNMODE IN ('ONLINE', 'ESEWA', 'FONEPAY', 'QR')) THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT * -1 ELSE NETAMNT END ELSE null END END AS [ONLINE],	
						CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN NSalesReturnVoucher ELSE
						CASE WHEN (TRNMODE = 'Sales Return Voucher') THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT * -1 ELSE NETAMNT END ELSE null END END AS [SalesReturnVoucher],	
						CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN A.PAXNO * -1 ELSE A.PAXNO END AS PAXNO,DIVISION			
						FROM 
						(
							SELECT A.TRNDATE,A.DIVISION,A.BSDATE, A.VCHRNO,A.TRNMODE,A.TOTAMNT,A.DCAMNT,A.TAXABLE,A.NONTAXABLE,A.VATAMNT,A.NETAMNT,ISNULL(A.STAX,0)STAX,B.NETCASH,B.NCREDIT,B.NCREDITCARD,
							B.NGVOUCHER,B.NPREPAID,B.N_ONLINE, B.NSalesReturnVoucher,ISNULL(A.CUSTOMER_COUNT,0)PAXNO,ISNULL(A.VNUM,A.VCHRNO)VNUM,(A.DCAMNT * 100)/A.TOTAMNT DISRATE,A.CHOLDER, A.VoucherType FROM RMD_TRNMAIN A
							LEFT JOIN BILLTENDER B ON A.VCHRNO = B.VNO AND A.DIVISION = B.DIV AND A.PhiscalID =B.PHISCALID WHERE 
							LEFT(A.VCHRNO,2) IN (@V1,@V2,@V3,@V4,@V5) AND A.DIVISION LIKE @DIV AND (A.TRNDATE >=@DATE1 AND TRNDATE <= @DATE2) AND (@PARTY = '%' OR (A.TRNAC = @PARTY OR A.PARAC = @PARTY OR A.RECEIVEBY = @CUSTID)) 
							AND ISNULL(A.SALESMANID, ISNULL(B.SALESMANID,'')) LIKE @SMAN 
							AND ((@COUNTERSALES = 0 AND ISNULL(RETTO,'') LIKE '%') OR (@COUNTERSALES = 1 AND ISNULL(RETTO,'') LIKE 'Counter Billing') OR (@COUNTERSALES = 2 AND ISNULL(RETTO,'') LIKE 'Table Billing'))
						) A
						WHERE ((@DISCOUNTEDSALES = 0 AND ABS(DISRATE)>=0 AND ISNULL(CHOLDER,'') LIKE '%') OR ((@DISCOUNTEDSALES = 1 AND ABS(DISRATE) >=@DISRATE AND ISNULL(CHOLDER,'') LIKE '%') 
						OR (@DISCOUNTEDSALES = 2 AND DISRATE >=@DISRATE AND ISNULL(CHOLDER,'') = 'CARD DISCOUNT')))
					) AS Z 
				) A ON A.MON = B.ID AND A.YER = B.YNAME GROUP BY B.MNAME,ISNULL(A.MON,B.ID),ISNULL(A.YER,B.YNAME)  ORDER BY ISNULL(YER,B.YNAME),ISNULL(MON,B.ID)
			
			
		END
END		
ELSE

	SELECT ISNULL(NAME,'N/A') SMAN_NAME,SUM(TOTAMNT) AS TOTAMNT, SUM(DCAMNT) AS DCAMNT, SUM(STAX)STAX, SUM(NETAMNT) AS NETAMNT, SUM(NONTAXABLE) AS NONTAXABLE,SUM(TAXABLE) AS TAXABLE,
	SUM(VATAMNT) AS VATAMNT, SUM(TAMNT) AS TAMNT,SUM(CASH) AS CASH, SUM(CCARD) AS CCARD, SUM(CREDIT) AS CREDIT,SUM(GVOUCHER) GVOUCHER,SUM(PREPAID) PREPAID,SUM([ONLINE])[ONLINE],SUM(SalesReturnVoucher) SalesReturnVoucher,SUM(PAXNO)PAXNO,SALESMANID
	FROM
	(
		SELECT A.TRNDATE,A.BSDATE, X.NAME,X.SALESMANID,
		CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.TOTAMNT *-1 ELSE A.TOTAMNT END AS TOTAMNT,
		CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.DCAMNT *-1 ELSE A.DCAMNT END AS DCAMNT,
		CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.STAX *-1 ELSE A.STAX END AS STAX,
		CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN (A.TAXABLE + A.NONTAXABLE)*-1 ELSE (A.TAXABLE + A.NONTAXABLE)  END AS NETAMNT,
		CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.NONTAXABLE  * -1 ELSE A.NONTAXABLE END AS NONTAXABLE,
		CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.TAXABLE  * -1 ELSE A.TAXABLE END AS TAXABLE,
		CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.VATAMNT * -1 ELSE A.VATAMNT END AS VATAMNT,
		CASE WHEN VoucherType IN (@V3,@V4,@V5) THEN A.NETAMNT * -1 ELSE A.NETAMNT END AS TAMNT,
		CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN NETCASH ELSE 
		CASE WHEN (TRNMODE = 'CASH') THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT *-1 ELSE NETAMNT END ELSE null END END AS CASH,
		CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN NCREDITCARD ELSE
		CASE WHEN TRNMODE IN ('CREDITCARD', 'CREDIT CARD') THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT *-1 ELSE NETAMNT END ELSE null END END AS CCARD,
		CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN NCREDIT ELSE
		CASE WHEN (TRNMODE = 'CREDIT') THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT * -1 ELSE NETAMNT END ELSE null END END AS CREDIT,
		CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN NGVOUCHER ELSE
		CASE WHEN (TRNMODE = 'GIFTVOUCHER') THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT * -1 ELSE NETAMNT END ELSE null END END AS GVOUCHER,
		CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN NPREPAID ELSE
		CASE WHEN (TRNMODE = 'PREPAID') THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT * -1 ELSE NETAMNT END ELSE null END END AS PREPAID,
		CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN N_ONLINE ELSE
		CASE WHEN (TRNMODE IN ('ONLINE', 'ESEWA', 'FONEPAY', 'QR')) THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT * -1 ELSE NETAMNT END ELSE null END END AS [ONLINE],
		CASE WHEN TRNMODE IN ('MIXEDMODE', 'Mixed') THEN NSalesReturnVoucher ELSE
		CASE WHEN (TRNMODE = 'Sales Return Voucher') THEN CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN NETAMNT * -1 ELSE NETAMNT END ELSE null END END AS [SalesReturnVoucher],	
		CASE WHEN LEFT(VCHRNO,2) IN (@V3,@V4,@V5) THEN A.PAXNO * -1 ELSE A.PAXNO END AS PAXNO,DIVISION			
		FROM 
		(
			SELECT A.TRNDATE,A.DIVISION,A.BSDATE, A.VCHRNO,A.TRNMODE,A.TOTAMNT,A.DCAMNT,A.TAXABLE,A.NONTAXABLE,A.VATAMNT,A.NETAMNT,ISNULL(A.STAX,0)STAX,B.NETCASH,B.NCREDIT,B.NCREDITCARD,
			B.NGVOUCHER,B.NPREPAID,B.N_ONLINE,B.NSalesReturnVoucher,ISNULL(A.CUSTOMER_COUNT,0)PAXNO,ISNULL(A.VNUM,A.VCHRNO)VNUM,(A.DCAMNT * 100)/A.TOTAMNT DISRATE,A.CHOLDER,ISNULL(A.SALESMANID, ISNULL(B.SALESMANID,'')) SALESMANID, A.VoucherType FROM RMD_TRNMAIN A
			LEFT JOIN BILLTENDER B ON A.VCHRNO = B.VNO AND A.DIVISION = B.DIV AND A.PhiscalID =B.PHISCALID WHERE 
			LEFT(A.VCHRNO,2) IN (@V1,@V2,@V3,@V4,@V5) AND A.DIVISION LIKE @DIV AND (A.TRNDATE >=@DATE1 AND TRNDATE <= @DATE2) AND (@PARTY = '%' OR (A.TRNAC = @PARTY OR A.PARAC = @PARTY OR A.RECEIVEBY = @CUSTID)) 
			AND ISNULL(A.SALESMANID, ISNULL(B.SALESMANID,'')) LIKE @SMAN 
			AND ((@COUNTERSALES = 0 AND ISNULL(RETTO,'') LIKE '%') OR (@COUNTERSALES = 1 AND ISNULL(RETTO,'') LIKE 'Counter Billing') OR (@COUNTERSALES = 2 AND ISNULL(RETTO,'') LIKE 'Table Billing'))
		) A LEFT JOIN SALESMAN X ON A.SALESMANID = X.SALESMANID
		WHERE ((@DISCOUNTEDSALES = 0 AND ABS(DISRATE)>=0 AND ISNULL(CHOLDER,'') LIKE '%') OR ((@DISCOUNTEDSALES = 1 AND ABS(DISRATE) >=@DISRATE AND ISNULL(CHOLDER,'') LIKE '%') 
		OR (@DISCOUNTEDSALES = 2 AND DISRATE >=@DISRATE AND ISNULL(CHOLDER,'') = 'CARD DISCOUNT')))
	) AS Z GROUP BY ISNULL(NAME,'N/A'), SALESMANID
	ORDER BY ISNULL(NAME,'N/A')
set nocount off