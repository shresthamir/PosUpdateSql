CREATE OR ALTER  function [dbo].[CurrencyNumberToWords](@num numeric(18,2))  
returns varchar(500)  
as  
begin  
declare @Cur varchar(3)='Rs',@cent varchar(10)='Paisa'  
select @Cur = ISNULL(CurrencySymbol, 'Rs.'), @cent = ISNULL(CentSymbol, 'Paisa') from setting  
declare @word varchar(500)  
declare @Rupees varchar(50),@paisa varchar(50),@WordRs varchar(500),@WordPaisa varchar(100)  
select @Rupees = PARSENAME(@num,2)  
select @paisa = PARSENAME(@num,1)  
select @WordRs= dbo.Num_ToWords(convert(numeric(18),@Rupees)),@WordPaisa=dbo.Num_ToWords(convert(numeric(2),@paisa))  
  
IF TRY_PARSE(@paisa as numeric(18,2)) = 0  
 begin  
  select @word= @cur + ' ' + @WordRs + ' only'  
 end  
else  
 begin  
  select @word= @cur + ' ' + @WordRs + ' and ' + @WordPaisa + ' ' + @cent + ' only'  
 end  
return @word  
end