CREATE OR ALTER VIEW vwVoucherLedgerParticulars
AS  
SELECT 'JV' VoucherType,  'JournaL Voucher' Particulars
UNION 
SELECT 'JN' VoucherType,  'Contra Voucher' Particulars
UNION 
SELECT 'IE' VoucherType,  'Income & Expenses Voucher' Particulars
UNION 
SELECT 'GN' VoucherType,  'General' Particulars
UNION 
SELECT 'PI' VoucherType,  'Purchase Voucher' Particulars
UNION 
SELECT 'PR' VoucherType,  'Purchase Return Voucher' Particulars
UNION 
SELECT 'SI' VoucherType,  'Sales Voucher' Particulars
UNION 
SELECT 'TI' VoucherType,  'Tax Invoice' Particulars
UNION 
SELECT 'SR' VoucherType,  'Sales Return  Voucher' Particulars
UNION 
SELECT 'CN' VoucherType,  'Credit Note Voucher' Particulars
UNION 
SELECT 'DN' VoucherType,  'Debit Note Voucher' Particulars
UNION 
SELECT 'IC' VoucherType,  'Intercompany Sales Voucher' Particulars
UNION 
SELECT 'IR' VoucherType,  'Intercompany Sales Return Voucher' Particulars
UNION
SELECT 'IV' VoucherType,  'Vehicle Sales Voucher' Particulars
UNION 
SELECT 'TO' VoucherType,  'Branch Transfer Out' Particulars
UNION  
SELECT 'TR' VoucherType,  'Branch Transfer In' Particulars
UNION
SELECT 'AC' VoucherType,  'Additional Cost Voucher' Particulars