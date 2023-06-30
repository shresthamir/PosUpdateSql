CREATE OR ALTER procedure [dbo].[RSP_CoversServedSummary_Report]
--DECLARE
@DIV VARCHAR(25)='%',
@DATE1 DATE = '01 JAN 1900',
@DATE2 DATE = '01 JAN 1900'
AS
set nocount on;
--SET @DIV = '%'; SET @DATE1 = '17 JUL 2021'; SET @DATE2 = '1 MAR 2023'

if @DATE1 <='01 JAN 2000' 
BEGIN
	SET @DATE1 = GETDATE(); 
	SET @DATE2 = GETDATE();
END

SELECT tables_served,covers_served,current_orders_value_served,
(current_orders_value_served/tables_served) average_orders_value_served_per_table,
(current_orders_value_served/covers_served) average_orders_value_served_per_cover
FROM
(
    SELECT count(distinct KM.KOTID) tables_served, sum(KM.PAX) covers_served,sum(TM.NETAMNT) current_orders_value_served
    FROM RMD_KOTMAIN KM JOIN RMD_KOTMAIN_STATUS S ON KM.KOTID = S.KOTID
	JOIN SALES_TRNMAIN TM ON S.REMARKS = TM.VCHRNO
    WHERE S.STATUS = 'BILLED' AND KM.TRNDATE BETWEEN @DATE1 AND @DATE2 AND KM.DIVISION LIKE @DIV
)A