CREATE or alter    PROC [dbo].[spSaveAuditLog] (@TableName varchar(50),  @InsertedJson nvarchar(max), @DeletedJson nvarchar(max))      
AS      
BEGIN TRY           
 Declare @KeyValue varchar(1000), @IgnoreFields VARCHAR(MAX)      
 Declare @TUser varchar(1000)  
 SELECT @KeyValue = KeyFielD, @IgnoreFields = IgnoreFields FROM vwTableKeys where TableName = @TableName
   Declare @KValue varchar(1000)  
 IF ((@InsertedJson IS NULL OR @InsertedJson =  '') AND @DeletedJson IS NOT NULL AND  @DeletedJson <> '')      
 BEGIN      
       select * INTO #DeleteResultTable from dbo.compare_jsonobject(@DeletedJson,@DeletedJson,@KeyValue) where SideIndicator  In ('==');         
    set @KValue = (select top 1 KeyValue from #DeleteResultTable);  
    set @TUser = (select top 1 TrnUser from #DeleteResultTable);     
    Insert into tblAuditLog(LogTime, TrnUser, TableName,[Key],FieldName,OldValue,NewValue,DbUser, AppName)  Values( GetDate(),@TUser ,@TableName,@KValue,'',@DeletedJson,'',SUSER_NAME(), APP_NAME());  
    
 END      
 ELSE IF ((@DeletedJson IS NULL OR @DeletedJson =  '') AND @InsertedJson IS NOT NULL AND  @InsertedJson <> '')      
 BEGIN      
        select * INTO #InsertResultTable from dbo.compare_jsonobject(@InsertedJson,@InsertedJson,@KeyValue) where SideIndicator  In ('==');            
  set @KValue = (select top 1 KeyValue from #InsertResultTable);  
  set @TUser = (select top 1 TrnUser from #InsertResultTable);     
  Insert into tblAuditLog(LogTime, TrnUser, TableName,[Key],FieldName,OldValue,NewValue,DbUser, AppName)  Values( GetDate(),@TUser ,@TableName,@KValue,'','',@InsertedJson,SUSER_NAME(), APP_NAME());   
 END      
 ELSE       
 BEGIN      
    select * INTO #UpdateResultTable from dbo.compare_jsonobject(@InsertedJson,@DeletedJson,@KeyValue) where SideIndicator Not In ('==') AND TheKey NOT IN (SELECT * FROM Split(@IgnoreFields, ','));  
    IF((select count(*) from #UpdateResultTable) > 0)      
    BEGIN      
     Insert into tblAuditLog      
   select GetDate(), CT.TRNUSER TRNUSER,@TableName,IsNull(CT.KeyValue, '') KeyValue, CT.Thekey,CT.TheTargetValue,CT.TheSourceValue,SUSER_NAME() DBUser, APP_NAME() AppName from #UpdateResultTable CT       
    END      
 END      
END TRY       
BEGIN CATCH       
 DECLARE @ERROR VARCHAR(MAX)    
 SELECT @ERROR = ERROR_PROCEDURE() +' | ' + ERROR_MESSAGE();    
 --RAISERROR(@ERROR,10,1) WITH LOG    
END CATCH; 