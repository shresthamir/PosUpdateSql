CREATE OR ALTER PROCEDURE [dbo].[SP_GETSCHEMEDISCOUNT] 
--DECLARE
@CODE VARCHAR(20),
@DIVISION VARCHAR(30)='%', 
@TENDERMODE VARCHAR(50) = '',
@IsAndroidBilling tinyint = 0
,@OrderTime VARCHAR(20) = NULL
AS
SET NOCOUNT ON
--SET @CODE='M10527'
        DECLARE @TrnTime TIME;
	SET @TrnTime = CONVERT(time, ISNULL(@OrderTime,GETDATE()))
	select A.DisID AS schemeID,c.Mcode,c.disrate as SchemeDisRate,c.disamount as SchemeDisAmount,a.ComboId,a.SchemeName,a.[priority],1 as MinQty,a.SchemeType, a.TenderMode, a.MaxDiscount      
  from Discount_Rate a     
  inner join vwSchemeSchedule b on a.ScheduleID=b.DisID     
  inner join Discount_SchemeDiscount c on a.DisID=c.DisID    
  inner join menuitem d on c.mcode = d.MCODE    
 where c.Mcode = @CODE and a.SchemeType ='Mcode' AND ISNULL(D.DISMODE,'DISCOUNTABLE') = 'DISCOUNTABLE' AND (ISNULL(A.TenderMode,'') = '' OR A.TenderMode = @TENDERMODE)    
 AND ((@DIVISION ='%' OR isnull(a.divisions,'') = '') or (@DIVISION <> '%' and @division in  (select * from split(a.divisions,',')))) AND a.IsActive = 1 AND C.IsActive = 1     
 AND @TrnTime BETWEEN CONVERT(TIME, ISNULL(b.TimeStart,'00:00:00')) AND CONVERT(TIME, ISNULL(b.TimeEnd,'00:00:00'))     
 union all     
      
 select a.DisID,c.mcode,d.disrate,d.disamount,a.comboid,a.schemename,a.priority,1 as MinQty,a.SchemeType, a.TenderMode, a.MaxDiscount from Discount_Rate a     
  inner join vwSchemeSchedule b on a.ScheduleID=b.DisID    
  inner join Discount_SchemeDiscount d on a.DisID=d.DisID    
  inner join menuitem c on c.mgroup = d.mgroup     
 where C.MCODE  = @CODE and a.SchemeType ='Mgroup' AND ISNULL(C.DISMODE,'DISCOUNTABLE') = 'DISCOUNTABLE' AND (ISNULL(A.TenderMode,'') = '' OR A.TenderMode = @TENDERMODE)    
 AND ((@DIVISION ='%' OR isnull(a.divisions,'') = '') or (@DIVISION <> '%' and @division in  (select * from split(a.divisions,',')))) AND a.IsActive = 1 AND D.IsActive = 1  
  AND @TrnTime BETWEEN CONVERT(TIME, ISNULL(b.TimeStart,'00:00:00')) AND CONVERT(TIME, ISNULL(b.TimeEnd,'00:00:00'))     
     
 union all     
 select a.DisID,c.mcode,d.disrate,d.disamount,a.comboid,a.schemename,a.priority,1 as MinQty,a.SchemeType, a.TenderMode, a.MaxDiscount from Discount_Rate a     
  inner join vwSchemeSchedule b on a.ScheduleID=b.DisID    
  inner join Discount_SchemeDiscount d on a.DisID=d.DisID    
  inner join menuitem c on d.Parent = c.PARENT      
 where C.Mcode   = @CODE and a.SchemeType ='Parent' AND ISNULL(C.DISMODE,'DISCOUNTABLE') = 'DISCOUNTABLE' AND (ISNULL(A.TenderMode,'') = '' OR A.TenderMode = @TENDERMODE)    
 AND ((@DIVISION ='%' OR isnull(a.divisions,'') = '') or (@DIVISION <> '%' and @division in  (select * from split(a.divisions,',')))) AND a.IsActive = 1 AND D.IsActive = 1     
 AND @TrnTime BETWEEN CONVERT(TIME, ISNULL(b.TimeStart,'00:00:00')) AND CONVERT(TIME, ISNULL(b.TimeEnd,'00:00:00'))     
     
 union all     
 select a.DisID,c.mcode,c.disrate,c.disamount,a.comboid,a.schemename,a.priority,c.Quantity MinQty,a.SchemeType, a.TenderMode, a.MaxDiscount from Discount_Rate a     
  inner join vwSchemeSchedule b on a.ScheduleID=b.DisID    
  inner join discount_combolist c on a.DisID  = c.disid      
  inner join menuitem d on c.mcode = d.MCODE    
 where c.mcode   = @CODE and a.SchemeType ='Combo' AND ISNULL(D.DISMODE,'DISCOUNTABLE') = 'DISCOUNTABLE' AND (ISNULL(A.TenderMode,'') = '' OR A.TenderMode = @TENDERMODE)    
 AND ((@DIVISION ='%' OR isnull(a.divisions,'') = '') or (@DIVISION <> '%' and @division in  (select * from split(a.divisions,',')))) AND a.IsActive = 1 and @IsAndroidBilling = 0    
 AND @TrnTime BETWEEN CONVERT(TIME, ISNULL(b.TimeStart,'00:00:00')) AND CONVERT(TIME, ISNULL(b.TimeEnd,'00:00:00'))     
     
 union all     
 select a.DisID,c.mcode,a.disrate,a.disamount,a.comboid,a.schemename,a.priority,a.quantity MinQty,a.SchemeType, a.TenderMode, a.MaxDiscount from Discount_Rate a     
  inner join vwSchemeSchedule b on a.ScheduleID=b.DisID    
  inner join discount_ifAnyItemsList c on a.DisID  = c.disid     
  inner join menuitem d on c.mcode = d.MCODE     
  where c.mcode   = @CODE and a.SchemeType ='AnyItems' AND ISNULL(D.DISMODE,'DISCOUNTABLE') = 'DISCOUNTABLE' AND (ISNULL(A.TenderMode,'') = '' OR A.TenderMode = @TENDERMODE)    
 AND ((@DIVISION ='%' OR isnull(a.divisions,'') = '') or (@DIVISION <> '%' and @division in  (select * from split(a.divisions,',')))) AND a.IsActive = 1 AND C.IsActive = 1 and @IsAndroidBilling = 0   
 AND @TrnTime BETWEEN CONVERT(TIME, ISNULL(b.TimeStart,'00:00:00')) AND CONVERT(TIME, ISNULL(b.TimeEnd,'00:00:00'))     
     
 union all     
 select a.DisID,C.mcode,C.disrate,C.disamount,a.comboid,a.schemename,a.priority,a.quantity MinQty,a.SchemeType, a.TenderMode, a.MaxDiscount from Discount_Rate a     
  inner join vwSchemeSchedule b on a.ScheduleID=b.DisID    
  inner join discount_ifAnyItemsList c on a.DisID  = c.disid      
  inner join menuitem d on c.mcode = d.MCODE    
 where c.mcode   = @CODE  and a.SchemeType ='Bulk' AND ISNULL(D.DISMODE,'DISCOUNTABLE') = 'DISCOUNTABLE' AND (ISNULL(A.TenderMode,'') = '' OR A.TenderMode = @TENDERMODE)    
 AND ((@DIVISION ='%' OR isnull(a.divisions,'') = '') or (@DIVISION <> '%' and @division in  (select * from split(a.divisions,',')))) AND a.IsActive = 1 AND C.IsActive = 1 and @IsAndroidBilling = 0    
 AND @TrnTime BETWEEN CONVERT(TIME, ISNULL(b.TimeStart,'00:00:00')) AND CONVERT(TIME, ISNULL(b.TimeEnd,'00:00:00'))

 union all         
 select a.DisID,c.mcode,d.disrate,d.disamount,a.comboid,a.schemename,a.priority,1 as MinQty,a.SchemeType, a.TenderMode, a.MaxDiscount from Discount_Rate a         
  inner join vwSchemeSchedule b on a.ScheduleID=b.DisID        
  inner join Discount_SchemeDiscount d on a.DisID=d.DisID        
  inner join menuitem c on c.MCAT = d.MCAT         
 where C.MCODE  = @CODE and a.SchemeType ='MCAT' AND ISNULL(C.DISMODE,'DISCOUNTABLE') = 'DISCOUNTABLE' AND (ISNULL(A.TenderMode,'') = '' OR A.TenderMode = @TENDERMODE)        
 AND ((@DIVISION ='%' OR isnull(a.divisions,'') = '') or (@DIVISION <> '%' and @division in  (select * from split(a.divisions,',')))) AND a.IsActive = 1 AND D.IsActive = 1         
 AND @TrnTime BETWEEN CONVERT(TIME, ISNULL(b.TimeStart,'00:00:00')) AND CONVERT(TIME, ISNULL(b.TimeEnd,'00:00:00'))       
 order by [priority]