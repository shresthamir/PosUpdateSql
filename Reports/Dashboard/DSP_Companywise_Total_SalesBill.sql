create    procedure  [dbo].[DSP_Companywise_Total_SalesBill]
 @Date1 datetime ,@Date2 datetime,@CompanyId varchar(20)='%'
as
--declare @Date1 datetime ='2020-11-1',@Date2 datetime='2020-11-30',@CompanyId varchar(20)='STF0016'

  select TotalSales [Total Sales],TotalBills [Total Bills],UnitSold [Units Sold],convert(numeric(30,4),TotalSales/TotalBills) [Avg Basket Value],convert(numeric(30,4),TotalSales/UnitSold) [Avg Sku Value]
  from(
       select count(case when tm.VoucherType in ('SI','TI') then tm.VCHRNO end)-count(case when tm.VoucherType in ('cn') then tm.VCHRNO end) TotalBills,
              convert(numeric(30,4),sum(case when tm.VoucherType in  ('SI','TI') then tp.TotalSales else -tp.TotalSales end)) TotalSales,
              sum(case when tm.VoucherType in  ('SI','TI') then tp.UnitSold else -tp.UnitSold end) UnitSold
        from rmd_trnmain tm  join
              (select tp.vchrno,sum(case when SETTING.ShowDashboardInNet=1 then tp.AMOUNT else tp.NETAMOUNT end) TotalSales,sum(tp.RealQty+tp.REALQTY_IN) UnitSold
              from rmd_trnprod tp,SETTING
              group  by vchrno
			  )tp on tm.vchrno=tp.vchrno
        where tm.trndate between @Date1 and @Date2 and tm.VoucherType in  ('SI','TI','cn') and tm.COMPANYID like @CompanyId
   )a

