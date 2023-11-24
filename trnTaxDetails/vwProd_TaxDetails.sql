CREATE OR ALTER VIEW vwProd_TaxDetails WITH SCHEMABINDING
AS
SELECT VCHRNO, VoucherType, MCODE, SNO, taxName, taxAccount, taxableAmount, taxAmount FROM dbo.trnProd_TaxDetails
UNION ALL
SELECT VCHRNO, VoucherType, MCODE, SNO, taxName, taxAccount, taxableAmount, taxAmount FROM dbo.abbProd_TaxDetails