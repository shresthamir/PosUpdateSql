IF OBJECT_ID('PK_RMD_Order_AdditionalDetail')  IS NULL
ALTER TABLE RMD_Order_AdditionalDetail ADD CONSTRAINT PK_RMD_Order_AdditionalDetail PRIMARY KEY (VCHRNO, SNO) 

IF OBJECT_ID('FK_RMD_Order_AdditionalDetail_OrderMain')  IS NULL
ALTER TABLE RMD_Order_AdditionalDetail ADD CONSTRAINT  FK_RMD_Order_AdditionalDetail_OrderMain FOREIGN KEY (VCHRNO, DIVISION, PhiscalID) REFERENCES RMD_ORDERMAIN (VCHRNO, DIVISION, PhiscalID)

IF OBJECT_ID('FK_RMD_Order_AdditionalDetail_MenuItem')  IS NULL
ALTER TABLE RMD_Order_AdditionalDetail ADD CONSTRAINT  FK_RMD_Order_AdditionalDetail_MenuItem FOREIGN KEY (MCODE) REFERENCES MENUITEM (MCODE)
