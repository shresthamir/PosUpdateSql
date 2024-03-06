/*
 * Create a dummy table vwDynamicTender so that SP RSP_SHIFTCLOSEREPORT can be created
 */
IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'vwDynamicTender')
CREATE TABLE vwDynamicTender(VCHRNO VARCHAR(25) NOT NULL)