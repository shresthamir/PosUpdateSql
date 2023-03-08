CREATE OR ALTER   procedure [dbo].[RSP_MonthlySalesComparision]
--DECLARE
@DIV VARCHAR(25)='%',
@thismonthstart DATE,
@thismonthend DATE,
@prevmonthstart DATE,
@prevmonthend DATE,
@rangeFlag BIT = 0,       --0:Daily | 1:Weekly
@isBsCalendar BIT = 0
AS
--SET @DIV = '%'; SET @thismonthstart = '17 NOV 2022'; SET @thismonthend = '15 DEC 2022'; SET @prevmonthstart = '18 oct 2022'; SET @prevmonthend = '16 NOV 2022'; SET @rangeFlag = 0; SET @isBsCalendar = 1

IF OBJECT_ID('TEMPDB..#Date') IS NOT NULL DROP TABLE #Date

DECLARE 
@max INT,
@cols nvarchar(1000)=N'',
@cols1 nvarchar(1000)=N'',
@query nvarchar(max)=N''

SELECT AD, IIF(@isBsCalendar=1, LEFT(MITI,2), DAY(AD)) [Day], ((IIF(@isBsCalendar=1, LEFT(MITI,2), DAY(AD))+-1) / 7) + 1 AS [Week], IIF(@isBsCalendar=1, SUBSTRING(MITI,4,2), MONTH(AD)) [Month]
into #Date
from DATEMITI where AD between @prevmonthstart and @thismonthend

select @max = max([Month]) from #Date
        
SELECT @cols1 = STUFF((SELECT DISTINCT ', ISNULL(' + QUOTENAME( [MONTH])+',0)' +' '+ IIF([Ad] <= @prevmonthend, 'LastMonth','ThisMonth') FROM #Date FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,1,'')

SELECT @cols = STUFF((SELECT DISTINCT ',' + QUOTENAME([MONTH]) FROM #Date FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,1,'')

IF @rangeFlag = 0
set @query='SELECT [Day],'+@cols1+' FROM
			(
				SELECT ISNULL(SUM(S.NETAMNT),0) SALES, D.[Day], D.[Month] FROM
				(
					SELECT TM.TRNDATE, TM.VCHRNO, TM.VOUCHERTYPE, NETAMNT * IIF(TM.VoucherType IN (''RE'',''CN''), -1, 1) NETAMNT FROM SALES_TRNMAIN TM
					WHERE TM.TRNDATE BETWEEN @prevmonthstart AND @thismonthend AND TM.DIVISION LIKE @DIV
				) S RIGHT JOIN #DATE D ON S.TRNDATE = D.AD
				GROUP BY D.[Day], D.[Month] 
			) SourceTable
        	PIVOT (SUM(SALES) for [MONTH] in (' + @cols + '))  PivotTable'
ELSE
set @query='SELECT ''Week''+cast([Week] as varchar(10)) [Week],'+@cols1+' FROM
			(
				SELECT ISNULL(SUM(S.NETAMNT),0) SALES, D.[Week], D.[Month] FROM
				(
					SELECT TM.TRNDATE, TM.VCHRNO, TM.VOUCHERTYPE, NETAMNT * IIF(TM.VoucherType IN (''RE'',''CN''), -1, 1) NETAMNT FROM SALES_TRNMAIN TM
					WHERE TM.TRNDATE BETWEEN @prevmonthstart AND @thismonthend AND TM.DIVISION LIKE @DIV
				) S RIGHT JOIN #DATE D ON S.TRNDATE = D.AD
				GROUP BY D.[Week], D.[Month] 
			) SourceTable
        	PIVOT (SUM(SALES) for [MONTH] in (' + @cols + '))  PivotTable'
--print @query
exec sp_executesql @query, N'@prevmonthstart date, @thismonthend date, @div varchar(3)', @prevmonthstart, @thismonthend, @DIV
IF OBJECT_ID('TEMPDB..#Date') IS NOT NULL DROP TABLE #Date

