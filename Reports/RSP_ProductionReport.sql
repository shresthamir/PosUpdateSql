CREATE OR ALTER   PROC [DBO].[RSP_ProductionReport]
--DECLARE
@DATE1 DATETIME,
@DATE2 DATETIME,
@DIVISION VARCHAR(100)='%',
@WAREHOUSE VARCHAR(1000)='%',
@MCODE VARCHAR(100)='%'
AS
--SELECT @DATE1='2024-01-31 00:00:00', @DATE2='2024-01-31 00:00:00'


IF OBJECT_ID('TEMPDB..#DATA') is not null drop table #DATA
IF OBJECT_ID('TEMPDB..#RESULT') is not null drop table #RESULT

SELECT IM.VCHRNO, IM.TRNDATE, IM.BSDATE, IM.REFBILL, IVP.MCODE ProductionItem, IVP.UNIT ProductionUnit, IVP.RATE UnitCost, IVP.REALQTY_IN ProductionQty, IVP.WAREHOUSE PD_WAREHOUSE
, IVC.MCODE ConsumptionItem, IVC.WAREHOUSE ConsumptionWarehouse, IVC.RATE ConsumptionRate, IVC.RealQty ConsumptionQty, IVC.UNIT ConsumptionUnit, IVC.REMARKS
, ROW_NUMBER() OVER(PARTITION BY IM.VCHRNO, IVP.MCODE ORDER BY IM.VCHRNO, IM.TRNDATE) XNO 
INTO #DATA FROM INVMAIN IM 
JOIN INVPROD IVP ON  IM.VCHRNO = IVP.VCHRNO  AND IVP.REALQTY_IN>0
JOIN INVPROD IVC ON IVC.RealQty>0 AND IVC.VCHRNO=IM.VCHRNO and 
(ivp.mcode = ivc.MasterMCode OR (IVC.MasterMCode IS NULL OR 1=1))
WHERE IM.VoucherType = 'PD'
AND IM.TRNDATE BETWEEN @DATE1 AND @DATE2
AND IM.DIVISION LIKE @DIVISION
AND IVP.WAREHOUSE LIKE @WAREHOUSE
AND IVP.MCODE LIKE @MCODE

--SELECT * FROM #DATA ORDER BY VCHRNO, XNO

SELECT IIF(XNO = 1, CONVERT(VARCHAR(100), SN), '') Sn
, IIF(XNO=1, VCHRNO, '') VoucherNo
, IIF(XNO=1, FORMAT(TRNDATE, 'dd MMM yyyy'), '') [Date]
, IIF(XNO=1, A.BSDATE, '') Miti
, IIF(XNO=1, A.REFBILL,'') ReferenceNo
, IIF(XNO=1, ProductionItem,'') ProductionItem
, IIF(XNO=1, A.ProductionUnit,'') ProductionUnit
, IIF(XNO=1, CONVERT(NUMERIC(18,2),A.UnitCost),NULL) UnitCost
, IIF(XNO=1, CONVERT(NUMERIC(18,2),A.ProductionQty),NULL) ProductionQty
, IIF(XNO=1, A.PD_WAREHOUSE,'') ProductionWarehouse
, A.ConsumptionItem, A.ConsumptionUnit, A.ConsumptionWarehouse
, CONVERT(NUMERIC(18,2),A.ConsumptionRate) ConsumptionRate, CONVERT(NUMERIC(18,2),A.ConsumptionQty) ConsumptionQty
, A.REMARKS FROM
(
	SELECT  RWN.ROWN SN, A.VCHRNO, A.TRNDATE, A.BSDATE,	A.REFBILL, PDM.DESCA ProductionItem, A.PD_WAREHOUSE, A.UnitCost, A.ProductionQty, A.ProductionUnit, PDC.DESCA ConsumptionItem
	, A.ConsumptionWarehouse, A.ConsumptionRate, A.ConsumptionQty, A.ConsumptionUnit, A.REMARKS, 'A' FLG, A.XNO 
	from #DATA A 
	JOIN MENUITEM PDM ON PDM.MCODE = A.ProductionItem
	JOIN MENUITEM PDC ON PDC.MCODE = A.ConsumptionItem
	JOIN 
	(
		SELECT DISTINCT ROW_NUMBER() OVER(ORDER BY VCHRNO) AS ROWN, VCHRNO FROM #DATA GROUP BY VCHRNO
	)RWN 
	ON A.VCHRNO=RWN.VCHRNO

	UNION

	SELECT DISTINCT   RWN.ROWN, A.VCHRNO, TRNDATE  DATE, NULL BSDATE, NULL REFNO, NULL DESCA, NULL PD_WAREHOUSE, NULL PDRATE, NULL PDQTY, NULL PDUNIT
	, NULL CONSUMPTION_ITEM, NULL PC_WAREHOUSE, NULL CONS_RATE, NULL CON_QTY, NULL  CONS_UNIT, NULL  REMARKS, 'ZZZZZZ' FLG, '999' XNO from #DATA A  
	JOIN 
	(
		SELECT DISTINCT ROW_NUMBER() OVER(ORDER BY VCHRNO) AS ROWN, VCHRNO FROM #DATA GROUP BY VCHRNO
	)RWN  
	ON A.VCHRNO=RWN.VCHRNO
) A

ORDER BY VCHRNO,  FLG, XNO, TRNDATE

IF OBJECT_ID('TEMPDB..#DATA') is not null drop table #DATA
IF OBJECT_ID('TEMPDB..#RESULT') is not null drop table #RESULT