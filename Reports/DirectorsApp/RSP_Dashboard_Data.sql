CREATE OR ALTER   procedure [dbo].[RSP_Dashboard_Data]
--DECLARE
@DIV VARCHAR(50) = '%',
@DATE1 DATE = '1 JAN 1970',
@DATE2 DATE = '1 JAN 1970'
AS

IF @DATE1 < '1 JAN 2000'
BEGIN
	SET @DATE2 = GETDATE()
	SET @DATE1 = GETDATE()
END

IF OBJECT_ID('TEMPDB..#DATA') IS NOT NULL DROP TABLE #DATA
IF OBJECT_ID('TEMPDB..#RESULT') IS NOT NULL DROP TABLE #RESULT

SELECT M.TRNDATE, T.TRNMODE, (T.AMOUNT - T.CHANGE) * IIF(M.VoucherType IN ('RE','CN'), -1, 1) NETAMNT
, IIF(M.VoucherType IN ('SI','TI'), 1, 0) Bills
, IIF(M.VoucherType IN ('RE','CN'), 1, 0) ReturnBills 
INTO #DATA
FROM SALES_TRNMAIN M WITH (NOLOCK) JOIN RMD_BILLTENDER T WITH (NOLOCK) ON M.VCHRNO= T.VCHRNO
WHERE M.DIVISION LIKE @DIV AND M.TRNDATE BETWEEN @DATE1 AND @DATE2

SELECT TRNDATE, IIF(A.TRNMODE IN ('Credit'), NETAMNT, 0) creditsales,
IIF(A.TRNMODE IN ('Cash'), NETAMNT, 0) cashsales,
IIF(A.TRNMODE IN ('Credit Card'), NETAMNT, 0) creditcardsales,
IIF(A.TRNMODE IN ('QR','Esewa', 'Fonepay', 'Moco', 'Nepal Pay', 'Smart Qr', 'Khalti', 'IME Pay'), NETAMNT, 0) onlinesales,
IIF(A.TRNMODE NOT IN ('Cash', 'Credit Card', 'Credit' ,'QR', 'Esewa', 'Fonepay', 'Moco', 'Nepal Pay', 'Smart Qr', 'Khalti', 'IME Pay'), NETAMNT, 0) othersales,
NETAMNT overallsales, Bills, ReturnBills
INTO #RESULT 
FROM #DATA A

SELECT '' [type],
	SUM(Bills) number_of_bills,
	CONVERT(DECIMAL(18,2), SUM(ReturnBills)) number_of_return_bills,
	CONVERT(DECIMAL(18,2), sum(creditsales))  total_credit_amount,
	CONVERT(DECIMAL(18,2), sum(cashsales)) total_cash_amount,
	CONVERT(DECIMAL(18,2), sum(creditcardsales)) total_creditcard_amount,
	CONVERT(DECIMAL(18,2), sum(onlinesales)) total_epayment_sales,
	CONVERT(DECIMAL(18,2), sum(othersales)) total_other_sales,
	CONVERT(DECIMAL(18,2), sum(overallsales)) total_sales
from #RESULT

IF OBJECT_ID('TEMPDB..#DATA') IS NOT NULL DROP TABLE #DATA
IF OBJECT_ID('TEMPDB..#RESULT') IS NOT NULL DROP TABLE #RESULT