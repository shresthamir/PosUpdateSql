IF EXISTS(SELECT * FROM PaymentModes WHERE PaymentModeName = 'CellPay')
DELETE FROM PaymentModes WHERE PaymentModeName = 'CellPay'

IF NOT EXISTS(SELECT * FROM PaymentModes WHERE PaymentModeName = 'Hamro Pay')
INSERT INTO PaymentModes (PAYMENTMODENAME, MODE) VALUES ('Hamro Pay', 'EPAYMENT')