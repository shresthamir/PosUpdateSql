CREATE OR ALTER PROC OSP_ValidateWarehouseDiscontinue
--DECLARE
@Warehouse VARCHAR(50)
AS
--SELECT @Warehouse = 'test';
DECLARE @COUNT INT, @PhiscalId VARCHAR(20), @Stock NUMERIC(18,2)

SELECT @COUNT = COUNT(*) FROM SALESTERMINAL WHERE WAREHOUSE = @Warehouse
IF @COUNT > 0
	THROW 50001, 'Warehouse is mapped on Sales Terminals. It cannot be discontinued.',1

SELECT @COUNT = COUNT(*) FROM USERPROFILES WHERE WAREHOUSE = @Warehouse
IF @COUNT > 0
	THROW 50002, 'Warehouse is mapped on Users. It cannot be discontinued.',1

SELECT @COUNT = COUNT(*) FROM MENUITEM WHERE WHOUSE = @Warehouse
IF @COUNT > 0
	THROW 50003, 'Warehouse is mapped on Products. It cannot be discontinued.',1

SELECT @PhiscalId = PhiscalID FROM COMPANY
SELECT @Stock =  ISNULL(SUM(REALQTY_IN - REALQTY),0) FROM RMD_TRNPROD WHERE WAREHOUSE = @Warehouse AND PhiscalID = @PhiscalId
GROUP BY MCODE

IF ISNULL(@Stock,0) <> 0
	THROW 50004, 'Warehouse Inventory is not Zero. It cannot be discontinued.',1
