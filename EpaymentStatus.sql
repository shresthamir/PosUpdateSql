IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'EpaymentStatus')
CREATE TABLE EpaymentStatus 
(
	[GUID] VARCHAR(50) NOT NULL, 
	TRNDATE DATETIME NOT NULL, 
	BillAmount DECIMAL(12,2) NOT NULL, 
	TRNUSER VARCHAR(25) NOT NULL, 
	CONSTRAINT PK_EpaymentStatus PRIMARY KEY ([GUID])
) 

IF NOT EXISTS (SELECT * FROM PaymentModes WHERE PAYMENTMODENAME = 'Smart QR')
INSERT INTO PaymentModes (PAYMENTMODENAME, ACID, MODE, SNO) VALUES ('Smart QR', '', 'EPAYMENT', 4)

IF NOT EXISTS (SELECT * FROM PaymentModes WHERE PAYMENTMODENAME = 'Nepal Pay')
INSERT INTO PaymentModes (PAYMENTMODENAME, ACID, MODE, SNO) VALUES ('Nepal Pay', '', 'EPAYMENT', 5)

IF NOT EXISTS (SELECT * FROM PaymentModes WHERE PAYMENTMODENAME = 'FonePay')
INSERT INTO PaymentModes (PAYMENTMODENAME, ACID, MODE, SNO) VALUES ('FonePay', '', 'EPAYMENT', 6)

IF NOT EXISTS (SELECT * FROM PaymentModes WHERE PAYMENTMODENAME = 'IME Pay')
INSERT INTO PaymentModes (PAYMENTMODENAME, ACID, MODE, SNO) VALUES ('IME Pay', '', 'EPAYMENT', 7)

IF NOT EXISTS (SELECT * FROM PaymentModes WHERE PAYMENTMODENAME = 'Khalti')
INSERT INTO PaymentModes (PAYMENTMODENAME, ACID, MODE, SNO) VALUES ('Khalti', '', 'EPAYMENT', 8)

IF NOT EXISTS (SELECT * FROM PaymentModes WHERE PAYMENTMODENAME = 'MOCO')
INSERT INTO PaymentModes (PAYMENTMODENAME, ACID, MODE, SNO) VALUES ('MOCO', '', 'EPAYMENT', 9)

IF NOT EXISTS (SELECT * FROM PaymentModes WHERE PAYMENTMODENAME = 'Hamro Pay')
INSERT INTO PaymentModes (PAYMENTMODENAME, ACID, MODE, SNO) VALUES ('Hamro Pay', '', 'EPAYMENT', 10)

IF EXISTS (SELECT * FROM PaymentModes WHERE PAYMENTMODENAME = 'FinPOS')
DELETE FROM PaymentModes WHERE PAYMENTMODENAME = 'FinPOS'

IF EXISTS (SELECT * FROM PaymentModes WHERE PAYMENTMODENAME = 'CellPay')
DELETE FROM PaymentModes WHERE PAYMENTMODENAME = 'CellPay'


IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Discount_Rate' AND COLUMN_NAME = 'TenderMode')
ALTER TABLE Discount_Rate ADD TenderMode VARCHAR(50) NULL

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Discount_Rate' AND COLUMN_NAME = 'MaxDiscount')
ALTER TABLE Discount_Rate ADD MaxDiscount DECIMAL (12,2) NOT NULL, CONSTRAINT DF_DiscountRate_MaxDiscount DEFAULT (0) FOR MaxDiscount WITH VALUES