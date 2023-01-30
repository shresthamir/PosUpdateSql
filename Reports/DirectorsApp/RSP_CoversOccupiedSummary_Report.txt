CREATE OR ALTER PROCEDURE [dbo].[RSP_CoversOccupiedSummary_Report]
@DIV varchar(25)='%'
as
--declare @DIV varchar(25)='JHM'
set nocount on;
SELECT a.tables_occupied, a.covers_occupied, b.current_orders_value_estimate,
    (b.current_orders_value_estimate/a.tables_occupied) average_orders_value_per_table,
    (b.current_orders_value_estimate/a.covers_occupied) average_orders_value_per_cover
FROM
(
    select sum(rkm.Pax) covers_occupied,count(distinct rkm.KOTID) tables_occupied
    from rmd_kotmain rkm inner join RMD_KOTMAIN_STATUS rks on rkm.KOTID=rks.KOTID  WHERE rks.STATUS = 'ACTIVE' and rkm.DIVISION like @DIV
)a,
(	
	SELECT sum(M.RATE_A* P.Quantity) current_orders_value_estimate
    FROM RMD_KOTPROD P JOIN RMD_KOTMAIN_STATUS S ON P.KOTID = S.KOTID JOIN MENUITEM M ON P.MCODE = M.MCODE WHERE S.STATUS = 'ACTIVE' and P.DIVISION like @DIV
)b