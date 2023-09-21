CREATE OR ALTER PROCEDURE OSP_GETITEMLIST      
--DECLARE      
@DIVISION VARCHAR(3),      
@WAREHOUSE VARCHAR(50),      
@TERMINAL VARCHAR(5),      
@RateGroupId INT = 0 ,   
@MCODE VARCHAR(50) = '%'  
AS      
DECLARE @ItemWiseWarehouse TINYINT, @hideRawItemsInBilling TINYINT = 1      
DECLARE @PRODUCTMAP TINYINT      
DECLARE @ItemWiseSCTax BIT      
DECLARE @EnableSTax BIT      
SELECT @PRODUCTMAP = PRODUCTMAP, @ItemWiseWarehouse =ItemWiseWarehouse, @EnableSTax = EnableServiceCharge, @ItemWiseSCTax = EnableServiceCharge & ItemWiseSchargeApply FROM SETTING   

SELECT @hideRawItemsInBilling = IIF(showRawItemsInBilling =1, 255,1) FROM SETTING
--DECLARE @RateGroupId INT      
--SELECT @RateGroupId = RateGroupID FROM DIVISION WHERE INITIAL = @DIVISION      
PRINT @ITEMWISESCTAX      
PRINT @ENABLESTAX      
      
SELECT DISTINCT A.MCODE,A.MENUCODE,A.DESCA,A.DESCB,A.PARENT,A.TYPE,ISNULL(A.BASEUNIT, '') BASEUNIT,A.ALTUNIT,A.CONFACTOR,       
A.RATE_A OriginalRate,      
CASE WHEN ISNULL(C.RG_RATE,0)=0 THEN A.RATE_A ELSE C.RG_RATE END RATE_A, A.RATE_B, A.RATE_C, A.BillingDisplay, A.IsQtyUnknown,      
0 RATE_D, A.VAT, LEVELS, BRAND, MODEL, A.MGROUP, DISMODE, A.DISRATE, A.MCAT1,       
A.DISAMOUNT, RECRATE, MARGIN, DISCONTINUE, ISNULL([PATH],'') [PATH], PTYPE,       
SUPCODE, ISNULL(A.MCAT, '') MCAT, SAC, SRAC, PAC, PRAC, GENERIC, ISUNKNOWN, A.EDATE, BARCODE, HASSERIAL, IIF(@ItemWiseSCTax = 1, HASSERVICECHARGE, @EnableSTax) HASSERVICECHARGE, DIMENSION,       
COLOR, ISNULL(PACK, 0) PACK, PRODTYPE, GWEIGHT, NWEIGHT, CBM, HASBATCH, SUPITEMCODE, LPDATE, CRDATE, TAXGROUP_ID, null LEADTIME,       
A.PRATE_A, CASE WHEN ISNULL(A.CRATE,0)=0 THEN A.PRATE_A ELSE ISNULL(A.CRATE,0) END CRATE, SCHEME_A,SCHEME_B,SCHEME_C,SCHEME_D,SCHEME_E,      
CASE WHEN ISNULL(A.CRATE,0) <> 0 THEN A.CRATE      
ELSE A.PRATE_A END AS COSTINGRATE, d.NATURETYPE,null SchemeName,      
CASE WHEN @ItemWiseWarehouse = 1 AND ISNULL(WHOUSE, '') <> '' THEN WHOUSE ELSE @WAREHOUSE END WHOUSE,      
MINLEVEL,MAXLEVEL,ROLEVEL,MINWARN,MAXWARN,ROWARN,location, a.ReqExpDate, A.IsSRateAgainstCRateNeglected, A.MAXSQTY      
FROM MENUITEM A OUTER APPLY DBO.FNGETRATEGROUP(A.MCODE, A.RATE_A, @RateGroupId) C      
LEFT JOIN COUNTERPRODUCT CP ON A.MGROUP = CP.PRODUCT       
LEFT JOIN ptype D on a.ptype= d.ptypeid      
left join TBL_ITEM_LOCATIONS l on a.MCODE=l.ITEM      
WHERE A.PTYPE NOT IN (@hideRawItemsInBilling, 12) AND      
A.DISCONTINUE NOT IN(1,2) AND ISNULL(A.DIVISIONS, @DIVISION) LIKE '%'+@DIVISION+'%'       
AND (@PRODUCTMAP = 0 OR CP.COUNTER = @TERMINAL) AND A.IsActive = 1   
AND (@MCODE = '%' OR A.MCODE like @MCODE OR A.MGROUP like @MCODE OR A.PARENT like @MCODE) 
