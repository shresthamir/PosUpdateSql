CREATE OR ALTER TRIGGER [dbo].[TRIGGER_PREVENT_HoldBill_ON_tblUserBillingRights] ON [dbo].[tblUserBillingRights] FOR INSERT,UPDATE
AS 
BEGIN
	IF TRIGGER_NESTLEVEL() > 1
		RETURN;
	DECLARE @MID VARCHAR(25), @OPEN TINYINT
	SELECT @MID = MID, @OPEN = [OPEN] FROM inserted
	IF @MID = 'Hold Bill' AND @OPEN = 1
	BEGIN
		ROLLBACK
		RAISERROR('Hold Bill feature is disabled for the time being.', 16, 1) WITH LOG
	END
END