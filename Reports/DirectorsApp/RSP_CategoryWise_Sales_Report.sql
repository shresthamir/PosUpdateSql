CREATE OR ALTER procedure [dbo].[RSP_CategoryWise_Sales_Report]  
--DECLARE
@DATE1 Date,
@DATE2 Date,
@DIV VARCHAR(3)='%'
AS
set nocount on;
--SELECT @date1= '2023-08-01', @date2='2023-09-17', @DIV = '%';

SELECT MI.MCAT1 category,  CONVERT(DECIMAL(18,2), SUM(IIF(a.VoucherType IN ('RE','CN'), -1, 1) * A.totalSales))  totalSales
FROM
(
	SELECT TP.MCODE, TM.VoucherType, SUM(TP.NETAMOUNT) totalSales
		FROM SALES_TRNMAIN TM WITH (NOLOCK)
		JOIN SALES_TRNPROD TP WITH (NOLOCK) ON TM.VCHRNO = TP.VCHRNO --AND TM.VoucherType = TP.VoucherType
	WHERE TRNDATE between @date1 and @date2 and tm.DIVISION  LIKE @DIV --AND TM.VoucherType IN ('SI','TI','CN','RE')
	GROUP BY TP.MCODE, TM.VoucherType
) A
JOIN MENUITEM MI ON A.MCODE = MI.MCODE
GROUP BY MI.MCAT1