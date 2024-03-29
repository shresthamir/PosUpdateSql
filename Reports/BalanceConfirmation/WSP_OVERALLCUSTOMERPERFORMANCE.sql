CREATE  OR ALTER PROCEDURE [dbo].[WSP_OVERALLCUSTOMERPERFORMANCE]
--DECLARE 
	@DATE1 DATE,
	@DATE2 DATE,
	@DIV VARCHAR(3)='%',
	@CCENTER VARCHAR(50) = '%',
	@ACID VARCHAR(25) = 'PA%',
	@PHISCALID VARCHAR(25),
	@COMPANYID VARCHAR(25)
AS
--SET @DATE1 = '2022-07-16'; SET @DATE2 = '2023-07-15';SET @ACID = 'PA0001'; SET @PHISCALID = '79/80'
IF @ACID = '%' 
	SET @ACID = 'PA%'
	
--set @DATE1='2021-07-16 00:00:00'; set @DATE2='2022-07-16 00:00:00';set @ACID=N'PA53'; set @COMPANYID=N'%'; set @PHISCALID=N'78/79'
set nocount ON

DECLARE @DIVISIONWISEVOUCHER AS TINYINT
SELECT @DIVISIONWISEVOUCHER = DIVISIONWISEVOUCHER FROM SETTING

IF OBJECT_ID('TEMPDB..#VLIST') IS NOT NULL DROP TABLE #VLIST
IF OBJECT_ID('TEMPDB..#RESULT1') IS NOT NULL DROP TABLE #RESULT1
IF OBJECT_ID('TEMPDB..#RESULT2') IS NOT NULL DROP TABLE #RESULT2
IF OBJECT_ID('TEMPDB..#RESULT3') IS NOT NULL DROP TABLE #RESULT3


SELECT DISTINCT CASE WHEN VNAME = 'INCOME' THEN 'RV' WHEN VNAME = 'EXPENSE' THEN 'PV' ELSE VNAME END VID INTO #VLIST 
FROM RMD_SEQUENCES WHERE VOUCHERTYPE IN ('RV','PV')
AND ISNULL(DIVISION,'') LIKE CASE WHEN @DIVISIONWISEVOUCHER = 1 THEN @DIV ELSE '%' END

--SELECT * FROM #VLIST

SELECT D.PTYPE, D.ACNAME,D.VATNO, D.ADDRESS,A_ACID, SUM(CASE WHEN A.TRNDATE<@DATE1 OR A.VOUCHERTYPE IN ('AO','OB') THEN DRAMNT-CRAMNT ELSE 0 END) OPENINGBL,
SUM(IIF(ISNULL(X.VID,'') <> '', CRAMNT-DRAMNT, 0)) * IIF(ISNULL(D.PType, 'C') = 'C',1,-1) PAYMENT,
SUM(DRAMNT)-SUM(CRAMNT) CLOSINGBL INTO #RESULT1 FROM RMD_ACLIST D
LEFT JOIN
(
	SELECT A.VCHRNO,A.A_ACID, B.TRNDATE, A.VOUCHERTYPE, A.DRAMNT, A.CRAMNT FROM RMD_TRNTRAN A 
	JOIN RMD_TRNMAIN B ON A.VCHRNO = B.VCHRNO AND A.DIVISION = B.DIVISION 
	WHERE A.A_ACID LIKE @ACID AND ISNULL(A.COSTCENTER,'') LIKE @CCENTER AND A.PhiscalID = @PHISCALID
) A ON A.A_ACID = D.ACID 
LEFT JOIN #VLIST X ON LEFT(A.VCHRNO,2) = X.VID
WHERE D.ACID LIKE @ACID
GROUP BY A.A_ACID,D.ACNAME,D.VATNO,D.ADDRESS, D.PType

--SELECT * FROM #RESULT1

SELECT ISNULL(PARAC,TRNAC) TRNAC,SUM(CASE WHEN VoucherType IN ('RE','PR') THEN TAXABLE*-1 ELSE TAXABLE END)TAXABLE,SUM(CASE WHEN VoucherType IN ('RE','PR') THEN NONTAXABLE*-1 ELSE NONTAXABLE END)NONTAXABLE,
SUM(CASE WHEN VoucherType IN ('RE','PR') THEN VATAMNT*-1 ELSE VATAMNT END)VATAMNT INTO #RESULT2 FROM RMD_TRNMAIN WHERE LEFT(VCHRNO,2) IN ('SI','TI','RE', 'PI', 'PR')
AND TRNDATE BETWEEN @DATE1 AND @DATE2 AND ISNULL(COSTCENTER,'') LIKE @CCENTER AND ISNULL(PARAC,TRNAC) LIKE @ACID GROUP BY ISNULL(PARAC,TRNAC)
--SELECT * FROM #RESULT2

SELECT ISNULL(A.PARAC,A.TRNAC) TRNAC,SUM(TAXABLE)TAXABLE,SUM(NONTAXABLE)NONTAXABLE,SUM(VATAMNT)VATAMNT INTO #RESULT3 FROM RMD_TRNMAIN A INNER JOIN 
(SELECT DISTINCT VCHRNO,DIVISION FROM RMD_TRNPROD B WHERE VoucherType IN ('CN','DN')) B ON A.VCHRNO = B.VCHRNO AND A.DIVISION = B.DIVISION
WHERE A.VoucherType IN ('CN','DN') AND TRNDATE BETWEEN @DATE1 AND @DATE2 AND ISNULL(A.COSTCENTER,'') LIKE @CCENTER AND ISNULL(A.PARAC,A.TRNAC) LIKE @ACID GROUP BY ISNULL(A.PARAC,A.TRNAC)
--SELECT * FROM #RESULT3

SELECT ACNAME,VATNO,ADDRESS,OPENINGBL,PTAXABLE,PNTAXABLE,PVAT,PRTAXABLE,PRNTAXABLE,PRVAT, NETTAXABLE,NETNONTAXABLE,VATAMNT,PAYMENT,
CASE WHEN ABS(ADJUSTMENT)>=1 THEN ADJUSTMENT ELSE 0 END ADJUSTMENT,CLOSINGBL,A_ACID FROM
(
	SELECT A.ACNAME,A.VATNO,A.ADDRESS,A.OPENINGBL,B.TAXABLE PTAXABLE,B.NONTAXABLE PNTAXABLE,B.VATAMNT PVAT,
	C.TAXABLE PRTAXABLE,C.NONTAXABLE PRNTAXABLE,C.VATAMNT PRVAT,
	(ISNULL(B.TAXABLE,0)-ISNULL(C.TAXABLE,0))NETTAXABLE,(ISNULL(B.NONTAXABLE,0)-ISNULL(C.NONTAXABLE,0))NETNONTAXABLE,(ISNULL(B.VATAMNT,0) - ISNULL(C.VATAMNT,0)) VATAMNT,
	ISNULL(A.PAYMENT,0)PAYMENT,ISNULL(A.CLOSINGBL,0)-(((ISNULL(A.OPENINGBL,0))+(ISNULL(B.TAXABLE,0)+ISNULL(B.VATAMNT,0)+ISNULL(B.NONTAXABLE,0))) - ((ISNULL(C.TAXABLE,0)+ISNULL(C.VATAMNT,0)+ISNULL(C.NONTAXABLE,0)) + ISNULL(A.PAYMENT,0)))  ADJUSTMENT,
	ISNULL(A.CLOSINGBL,0) CLOSINGBL, A.A_aCID FROM #RESULT1 A 
	LEFT JOIN #RESULT2 B ON A.A_ACID = B.TRNAC 
	LEFT JOIN #RESULT3 C ON A.A_ACID = C.TRNAC
) A ORDER BY A.ACNAME


IF OBJECT_ID('TEMPDB..#VLIST') IS NOT NULL DROP TABLE #VLIST
IF OBJECT_ID('TEMPDB..#RESULT1') IS NOT NULL DROP TABLE #RESULT1
IF OBJECT_ID('TEMPDB..#RESULT2') IS NOT NULL DROP TABLE #RESULT2
IF OBJECT_ID('TEMPDB..#RESULT3') IS NOT NULL DROP TABLE #RESULT3
set nocount oFF