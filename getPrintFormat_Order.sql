CREATE OR ALTER PROC [dbo].[getPrintFormat_Order]
--DECLARE
@vchrno VARCHAR(25),
@division varchar(10),
@phiscalid varchar(10)
AS
--SELECT @VCHRNO = 'SO286-JYC-80/81', @DIVISION = 'JYC', @PHISCALID = '80/81'
BEGIN
SELECT M.PhiscalID ,M.VCHRNO vchrno,M.DIVISION division,M.ORDERNO , M.TRNDATE trndate , M.TRNTIME trntime ,M.MEMBERNO,M.DELIVERYDATE ESTIMATEDDELIVERY,M.REMARKS,M.TRNUSER trnuser
, M.DELIVERYADDRESS billadd,M.DELIVERYTIME deltime, M.CHALANNO chalanno, M.CustomerName billto,M.MOBILENO mobile, M.ADVANCE advance, M.TRNMODE trnmode, P.ITEMDESC, P.MCODE, P.BC
, AC.ACID,AC.ACNAME, CONVERT(NUMERIC(18,2),(M.NETAMNT)) netamnt, AC.ADDRESS,AC.PHONE, P.ALTQTY - ISNULL(T.QUANTITY, 0) totqty, P.RATE, (P.ALTQTY - ISNULL(T.QUANTITY, 0)) * P.ALTRATE AMOUNT
, MT.DESCA, B.BILLTOTEL billpan, ISNULL(P.INDDISCOUNTRATE,0) INDDISRATE, M.DCRATE * 100 dcrate, P.ALTUNIT,P.INDDISCOUNTRATE, CONVERT(INT, P.SNO) SN,0 tender, 0 change, M.DCAMNT dcamnt
, 0 taxable, 0 nontaxable, M.VATAMNT vatamnt, 0 tender, 0 change, C.TELA contact, C.[ADDRESS] DIVADD, null bsdate ,RO.Flavour ,RO.Design,
RO.Shape, RO.CakeMessage,CONVERT(NUMERIC(18,2),(m.NETAMNT -m.ADVANCE)) due
from RMD_ORDERMAIN M
join RMD_ORDERPROD P on P.VCHRNO = M.VCHRNO 
join MENUITEM MT on P.MCODE = MT.MCODE 
LEFT JOIN RMD_Order_AdditionalDetail RO ON P.VCHRNO =RO.VCHRNO
LEFT JOIN RMD_ACLIST AC ON M.TRNAC = AC.ACID
LEFT JOIN
( 
	SELECT TM.REFORDBILL, TP.MCODE, SUM(TP.Quantity) Quantity   FROM RMD_TRNMAIN TM 
	JOIN RMD_TRNPROD TP ON TM.VCHRNO = TP.VCHRNO            
	GROUP BY TM.REFORDBILL, TP.MCODE
) T ON M.VCHRNO = T.REFORDBILL AND P.MCODE = T.MCODE 
LEFT JOIN
(
	select RTM.VCHRNO,AC.BILLTOTEL , SUM(ATN.CRAMNT - ATN.DRAMNT) ADVANCE from RMD_ORDERMAIN RTM 
	join RMD_TRNMAIN AC on RTM.VCHRNO = AC.REFORDBILL
	join RMD_TRNTRAN ATN on AC.VCHRNO = ATN.VCHRNO
	WHERE  RTM.VCHRNO = @vchrno
	GROUP BY RTM.VCHRNO,AC.BILLTOTEL
) B ON B.VCHRNO = M.VCHRNO, COMPANY C 
WHERE P.QUANTITY - isnull(T.Quantity, 0) > 0 AND M.ORDERNO = @vchrno AND M.DIVISION = @division AND M.PhiscalID = @phiscalid

SELECT  vchrno,DIVISION, PhiscalID,ITEMDESC,unit,quantity, FORMAT(IIF(MT.VAT = 0, 1,1.13) * RATE,'N2') rate, FORMAT(RATE,'N2') rateExVat, amount, P.VAT vat,  P.SNO SNO,0 taxable, 0 nontaxable, MT.menucode
from  RMD_ORDERPROD P
join MENUITEM MT on P.MCODE = MT.MCODE 
WHERE vchrno = @vchrno AND DIVISION = @division AND PhiscalID = @phiscalid

SELECT 'TEST'
END