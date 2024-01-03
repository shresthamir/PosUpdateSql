CREATE OR ALTER TRIGGER [dbo].[TRIGGER_AUDIT_RMD_ACLIST] ON [dbo].[RMD_ACLIST]
FOR Insert,update,delete
AS
SET XACT_ABORT OFF;
DECLARE @InsertedJson nvarchar(max);
DECLARE @DeletedJson nvarchar(max);
SET @InsertedJson = (select * from inserted  for json auto)
SET @DeletedJson = (select * from deleted  for json auto)
EXEC spSaveAuditLog @TableName = N'RMD_ACLIST' , @InsertedJson = @InsertedJson , @DeletedJson = @DeletedJson;