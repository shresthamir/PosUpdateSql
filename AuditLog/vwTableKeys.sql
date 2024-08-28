CREATE OR ALTER VIEW vwTableKeys    
AS    
SELECT 'MENUITEM' TableName, 'MCODE' KeyField, 'ROW_VERSION,ORIGIN_ROW_VERSION,STAMP,EDATE,TRNUSER' IgnoreFields
	
Union All   
SELECT 'BARCODE' TableName, 'MCODE,BCODE' KeyField, 'ROW_VERSION,ORIGIN_ROW_VERSION' IgnoreFields
	
Union All    
SELECT 'Rmd_Aclist' TableName, 'ACID' KeyField, 'ROW_VERSION,ORIGIN_ROW_VERSION' IgnoreFields
  
Union All    
SELECT 'Discount_Rate' TableName, 'DisID,Mgroup,Parent,Mcode' KeyField, 'ROW_VERSION,ORIGIN_ROW_VERSION' IgnoreFields
  
Union All    
SELECT 'Discount_SchemeDiscount' TableName, 'DisID,Mgroup,Parent,Mcode' KeyField, 'ROW_VERSION,ORIGIN_ROW_VERSION' IgnoreFields
    
Union All    
SELECT 'Discount_ComboList' TableName, 'DisID,comboId' KeyField, 'ROW_VERSION,ORIGIN_ROW_VERSION' IgnoreFields
    
Union All    
SELECT 'Discount_IfAnyItemsList' TableName, 'DisID,Mcode' KeyField, 'ROW_VERSION,ORIGIN_ROW_VERSION' IgnoreFields
    
Union All    
SELECT 'DISCOUNT_SCHEME' TableName, 'DisID' KeyField, 'ROW_VERSION,ORIGIN_ROW_VERSION' IgnoreFields
    
Union All    
SELECT 'Setting' TableName, '' KeyField, 'ROW_VERSION,ORIGIN_ROW_VERSION' IgnoreFields

Union All    
SELECT 'ReceipeMain' TableName, 'ENO' KeyField, 'ROW_VERSION,ORIGIN_ROW_VERSION,TrnUser' IgnoreFields

Union All    
SELECT 'ReceipeProd' TableName, 'ENO,RMCODE' KeyField, 'ROW_VERSION,ORIGIN_ROW_VERSION,TrnUser' IgnoreFields