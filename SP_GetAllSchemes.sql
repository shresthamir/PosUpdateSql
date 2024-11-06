CREATE OR ALTER   PROC SP_GetAllSchemes
--DECLARE 
@JSON VARCHAR(5000)
, @MemberScheme VARCHAR(50) = ''
, @DIVISION VARCHAR(3) = '%'
, @TENDERMODE VARCHAR(50) = ''
AS
SET NOCOUNT ON
--SELECT @JSON = '[{"MCODE":"MMMD3","BC":"T4","BATCH":null,"ALTUNIT":"pcs","SNO":1,"CRATE":0.0,"RATE":0.0}]', @MemberScheme = 'SchemeA'
IF OBJECT_ID('TEMPDB..#ITEMS') IS NOT NULL DROP TABLE #ITEMS
IF OBJECT_ID('TEMPDB..#SCHEME') IS NOT NULL DROP TABLE #SCHEME

SELECT A.* INTO #ITEMS FROM OPENJSON(@JSON) 
CROSS APPLY OPENJSON(VALUE) 
WITH
(
	MCODE VARCHAR(25) '$.MCODE',
	BC VARCHAR(25) '$.BC',
	BATCH VARCHAR(25) '$.BATCH',
	ALTUNIT VARCHAR(25) '$.ALTUNIT',
	SNO SMALLINT '$.SNO'
	--,CRATE NUMERIC(18,8) '$.CRATE'
	--,RATE NUMERIC(18,8) '$.RATE'
) A

SELECT a.DisID schemeID, ISNULL(ISNULL(C.mcode, P.MCODE),M.MCODE) MCODE,C.disrate SchemeDisRate,C.disamount SchemeDisAmount,a.comboid,a.schemename,1 MinQty,a.SchemeType, 1 IsLoyalty, a.TenderMode, a.MaxDiscount
INTO #SCHEME FROM Discount_Rate A 
INNER JOIN vwSchemeSchedule b on a.ScheduleID =b.DisID
INNER JOIN discount_SchemeDiscount c on a.DisID  = c.disid 
JOIN MEMBERSCHEME MS ON MS.SCHEMEID = a.schemetype
LEFT join menuitem P on P.Parent = c.PARENT
LEFT join menuitem M on M.MGROUP = c.MGroup  
LEFT JOIN MENUITEM I ON I.MCODE = C.Mcode
--where (c.mcode   = @CODE OR ISNULL(P.MCODE, '') = @CODE OR ISNULL(M.MCODE, '') = @CODE)
WHERE ((@DIVISION ='%' OR isnull(a.divisions,'') like '%') or (@DIVISION <> '%' and @division in  (select * from split(a.divisions,',')))) 
AND A.IsActive = 1 AND C.IsActive = 1
AND ISNULL(P.DISMODE, 'DISCOUNTABLE') = 'DISCOUNTABLE'
AND ISNULL(M.DISMODE, 'DISCOUNTABLE') = 'DISCOUNTABLE'
AND ISNULL(I.DISMODE, 'DISCOUNTABLE') = 'DISCOUNTABLE'
AND (ISNULL(A.TenderMode,'') = '' OR A.TenderMode = @TENDERMODE)
AND MS.SCHEMEID = @MemberScheme
UNION ALL

SELECT a.DisID schemeID, ISNULL(ISNULL(C.mcode, P.MCODE),M.MCODE) MCODE,C.disrate SchemeDisRate,C.disamount SchemeDisAmount,a.comboid,a.schemename,1 MinQty, A.SchemeType, 0 IsLoyalty, a.TenderMode, a.MaxDiscount
FROM Discount_Rate A 
INNER JOIN vwSchemeSchedule b on a.ScheduleID =b.DisID
INNER JOIN discount_SchemeDiscount c on a.DisID  = c.disid 
LEFT JOIN MEMBERSCHEME MS ON MS.SCHEMEID = a.schemetype
LEFT join menuitem P on P.Parent = c.PARENT
LEFT join menuitem M on M.MGROUP = c.MGroup  
LEFT JOIN MENUITEM I ON I.MCODE = C.Mcode
where ((@DIVISION ='%' OR isnull(a.divisions,'') like '%') or (@DIVISION <> '%' and @division in  (select * from split(a.divisions,',')))) 
AND A.IsActive = 1 AND C.IsActive = 1
AND ISNULL(P.DISMODE, 'DISCOUNTABLE') = 'DISCOUNTABLE'
AND ISNULL(M.DISMODE, 'DISCOUNTABLE') = 'DISCOUNTABLE'
AND ISNULL(I.DISMODE, 'DISCOUNTABLE') = 'DISCOUNTABLE'
AND (ISNULL(A.TenderMode,'') = '' OR A.TenderMode = @TENDERMODE)
AND MS.SCHEMEID IS NULL

UNION ALL

select a.DisID,c.mcode,c.disrate,c.disamount,a.comboid,a.schemename,c.Quantity MinQty,a.SchemeType, 0 IsLoyalty, a.TenderMode, a.MaxDiscount from Discount_Rate a 
inner join vwSchemeSchedule b on a.ScheduleID=b.DisID
inner join discount_combolist c on a.DisID  = c.disid  
inner join menuitem d on c.mcode = d.MCODE
where a.SchemeType ='Combo' AND ISNULL(D.DISMODE,'DISCOUNTABLE') = 'DISCOUNTABLE' 
AND A.IsActive = 1 AND C.IsActive = 1
AND (ISNULL(A.TenderMode,'') = '' OR A.TenderMode = @TENDERMODE)
AND ((@DIVISION ='%' OR isnull(a.divisions,'') = '') or (@DIVISION <> '%' and @division in  (select * from split(a.divisions,','))))

union

select a.DisID,c.mcode,C.disrate,C.disamount,a.comboid,a.schemename,a.quantity MinQty,a.SchemeType, 0 IsLoyalty, a.TenderMode, a.MaxDiscount from Discount_Rate a 
inner join vwSchemeSchedule b on a.ScheduleID=b.DisID
inner join discount_ifAnyItemsList c on a.DisID  = c.disid 
inner join menuitem d on c.mcode = d.MCODE
where a.SchemeType IN ('AnyItems','Bulk') 
AND A.IsActive = 1 AND C.IsActive = 1
AND ISNULL(D.DISMODE,'DISCOUNTABLE') = 'DISCOUNTABLE' 
AND (ISNULL(A.TenderMode,'') = '' OR A.TenderMode = @TENDERMODE)
AND ((@DIVISION ='%' OR isnull(a.divisions,'') = '') 
or (@DIVISION <> '%' and @division in  (select * from split(a.divisions,','))))

SELECT S.*, O.SchemeOrder [Priority], O.CanStackOnManualDiscount, O.CanStackOnPrevScheme, O.CanStackNextScheme FROM #ITEMS I JOIN #SCHEME S ON I.MCODE = S.MCODE 
JOIN vwSchemePriority O ON S.SchemeType = O.SchemeType AND S.schemeID = O.SchemeId
ORDER BY  O.SchemeOrder

SET NOCOUNT OFF