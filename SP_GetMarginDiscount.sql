CREATE OR ALTER  PROC SP_GetMarginDiscount  
--DECLARE   
@JSON VARCHAR(MAX),  
@MemberScheme VARCHAR(50) = ''  
AS  
  
SET NOCOUNT ON  
/*  
DECLARE @DiscountOnMargin BIT = 1  
SET @JSON = '[  
  {  
    "MCODE": "M10000",  
    "BC": "94.116",  
    "BATCH": "",  
 "ALTUNIT" : "PC",  
 "SNO" : 1,  
 "REALQTY" : 1,  
    "CRATE": 55.00,  
 "RATE": 203.54  
  },  
  {  
    "MCODE": "M10001",  
    "BC": "94.117",  
    "BATCH": "",  
 "ALTUNIT" : "PC",  
 "SNO" : 2,  
 "REALQTY" : 1,  
    "CRATE": 88.00,  
 "RATE": 92.92  
  },  
  {  
    "MCODE": "M10004",  
    "BC": "94.120",  
    "BATCH": "",  
 "ALTUNIT" : "PC",  
 "SNO" : 3,  
    "CRATE": 500.00,  
 "RATE": 175.22  
  }  
]'  
SET @MemberScheme = 'SchemeA'  
*/  
IF OBJECT_ID('TEMPDB..#MARGIN') IS NOT NULL DROP TABLE #MARGIN  
  
SELECT A.*, A.RATE - A.CRATE MarginAmt, 100 * (A.RATE - A.CRATE)/A.CRATE Margin INTO #margin FROM OPENJSON(@JSON)   
CROSS APPLY OPENJSON(VALUE)   
WITH  
(  
 MCODE VARCHAR(25) '$.MCODE',  
 BC VARCHAR(25) '$.BC',  
 BATCH VARCHAR(25) '$.BATCH',  
 ALTUNIT VARCHAR(25) '$.ALTUNIT',  
 SNO SMALLINT '$.SNO',  
 CRATE NUMERIC(18,8) '$.CRATE',  
 RATE NUMERIC(18,8) '$.RATE'  
) A  
  
select A.MSchemId, A.MSchmeName, M.*, C.FromMargin, c.ToMargin, c.DiscountRate, c.DiscountAmount  
from MarginScheme a   
inner join vwSchemeSchedule b on a.ScheduleID = b.DisID   
inner join MarginSchemeDetails c on a.MSchemId = C.MSchemeId  
INNER JOIN #margin M ON M.Margin > C.FromMargin AND M.Margin<=C.ToMargin  
JOIN MENUITEM P ON M.MCODE = P.MCODE  
WHERE (ISNULL(A.MemberScheme,'') = '' OR A.MemberScheme = @MemberScheme)  
AND ISNULL(P.DISMODE, 'DISCOUNTABLE') = 'DISCOUNTABLE'  
AND CONVERT(TIME,GETDATE()) BETWEEN CONVERT(TIME, ISNULL(b.TimeStart,'00:00:00')) AND CONVERT(TIME, ISNULL(b.TimeEnd,'00:00:00'))
  
SET NOCOUNT OFF