IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'SYNCTABLE_CLIENT')
	AND NOT EXISTS (SELECT * FROM SYNCTABLE_CLIENT WHERE SYNCNAME = 'SyncCheckSum_FiscalYear')
	INSERT INTO SYNCTABLE_CLIENT VALUES('SyncCheckSum_FiscalYear',0,'T')