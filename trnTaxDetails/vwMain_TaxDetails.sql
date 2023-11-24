CREATE OR ALTER VIEW vwMain_TaxDetails WITH SCHEMABINDING
AS
SELECT VCHRNO, VoucherType, taxName, taxAccount, taxableAmount, taxAmount FROM dbo.trnMain_TaxDetails
UNION ALL
SELECT VCHRNO, VoucherType, taxName, taxAccount, taxableAmount, taxAmount FROM dbo.abbMain_TaxDetails