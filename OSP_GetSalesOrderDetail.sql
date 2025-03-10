CREATE OR ALTER PROC OSP_GetSalesOrderDetail
--DECLARE
@VCHRNO VARCHAR(25)
AS
--SELECT @VCHRNO = 'SO1010-MMX-80/81'
SELECT OM.VCHRNO orderNo, OP.mCode , OP.BC barcode, MI.MENUCODE itemCode, MI.DESCA itemName, OP.ALTUNIT unit, OP.ALTRATE rate
, COALESCE(NULLIF(OP.ALTQTY,0), OP.ALTQTY_IN) orderQuantity
, SUM(ISNULL(TP_TI.ALTQTY,0)) soldQuantity
, COALESCE(NULLIF(OP.ALTQTY,0), OP.ALTQTY_IN) - SUM(ISNULL(TP_TI.ALTQTY,0)) remainingQuantity
,IIF(ISNULL(OP.INDDISCOUNTRATE,0) = 0, IIF(OP.AMOUNT = 0 , 0 , (OP.INDDISCOUNT/  OP.AMOUNT)*100),OP.INDDISCOUNTRATE ) discountRate
, OM.remarks FROM RMD_ORDERMAIN OM 		
INNER JOIN RMD_ORDERPROD OP ON OM.VCHRNO = OP.VCHRNO AND OM.DIVISION = OP.DIVISION AND OM.PhiscalID = OP.PhiscalID
LEFT JOIN MENUITEM MI ON OP.MCODE = MI.MCODE
LEFT JOIN MULTIALTUNIT U ON OP.MCODE = U.MCODE AND OP.ALTUNIT = U.ALTUNIT
LEFT JOIN
(
    SELECT VCHRNO, DIVISION, PHISCALID, MCODE, BC, ALTUNIT, INVOICENO, RATE, CASE WHEN ISNULL(ALTQTY, 0) = 0 THEN REALQTY ELSE ALTQTY END ALTQTY, REALQTY 
	FROM RMD_TRNPROD WHERE VoucherType IN ('SI', 'TI') AND ISNULL(REALQTY, 0) >= 0 AND INVOICENO = @VCHRNO
) TP_TI ON OP.MCODE = TP_TI.MCODE AND ISNULL(OP.BC, '') = ISNULL(TP_TI.BC, '') AND OP.ALTUNIT = TP_TI.ALTUNIT AND OP.VCHRNO = TP_TI.INVOICENO AND OP.DIVISION = TP_TI.DIVISION AND ABS(OP.RATE - TP_TI.RATE) < 0.01 --AND OP.PhiscalID = TP_TI.PhiscalID 
WHERE OM.VCHRNO = @VCHRNO  AND OM.[STATUS] <> 10
GROUP BY OM.VCHRNO, OM.TRNAC, OP.MCODE, OP.BC,OP.INDDISCOUNTRATE, MI.DESCA, MI.MENUCODE, OP.RATE, U.CONFACTOR, OP.ALTRATE, OP.ALTUNIT, OP.REALRATE, OP.UNIT, COALESCE(NULLIF(OP.ALTQTY,0), OP.ALTQTY_IN)
,OP.INDDISCOUNT, OP.AMOUNT,OM.REMARKS,OM.TOTALFLATDISCOUNT,OP.FLATDISCOUNT,OP.INDDISCOUNT
HAVING COALESCE(NULLIF(OP.ALTQTY,0), OP.ALTQTY_IN) - SUM(ISNULL(TP_TI.ALTQTY, 0)) > 0