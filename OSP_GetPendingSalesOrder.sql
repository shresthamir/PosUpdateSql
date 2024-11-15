CREATE OR ALTER PROC OSP_GetPendingSalesOrder
@division VARCHAR(3),
@pageNumber INT,
@pageSize INT
AS
DROP TABLE IF EXISTS #Result
SELECT  DISTINCT OM.vchrno, OM.chalanNo, OM.trnDate, OM.trnTime, OM.TRNAC trnAc, OM.BILLTO customerName, OM.BILLTOADD customerAddress, A.mobile, A.vatNo, OM.NETAMNT billAmount, OM.STAMP
, DENSE_RANK() OVER (ORDER BY OM.VCHRNO) + dense_rank() over (ORDER BY OM.VCHRNO DESC) - 1 totalRows
INTO #Result
FROM rmd_ordermain OM WITH (NOLOCK)
JOIN RMD_ORDERPROD OP WITH (NOLOCK) ON OM.VCHRNO = OP.VCHRNO 
JOIN RMD_ACLIST A ON OM.TRNAC = A.ACID
LEFT JOIN
(
	SELECT TM.REFORDBILL, TP.MCODE, SUM(TP.Quantity) Quantity FROM RMD_TRNMAIN TM WITH (NOLOCK)  
	JOIN RMD_TRNPROD TP WITH (NOLOCK) ON TM.VCHRNO = TP.VCHRNO 
	GROUP BY TM.REFORDBILL, TP.MCODE
) T ON OM.VCHRNO = T.REFORDBILL AND OP.MCODE = T.MCODE 
WHERE OM.VCHRNO LIKE 'SO%' AND OM.DIVISION = @division AND OP.QUANTITY - isnull(T.Quantity, 0) > 0 AND OM.[STATUS] <> 10
ORDER BY STAMP OFFSET @pageSize * (@pageNumber - 1) ROWS FETCH NEXT @pageSize ROWS ONLY

SELECT vchrno, chalanNo, trnDate, trnTime, trnAc, customerName, customerAddress, mobile, vatNo, billAmount FROM #Result

SELECT TOP 1 totalRows FROM #Result