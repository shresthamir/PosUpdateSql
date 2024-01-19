CREATE TABLE kotProd_ChoiceItems 
(
	kotId INT NOT NULL,
	kot VARCHAR(50) NULL,
	eno INT NOT NULL,
	division VARCHAR(3) NOT NULL,
	rawMCode VARCHAR(25) NOT NULL,
	sno INT NOT NULL,
	qty NUMERIC(12,3) NOT NULL, 
	parentMCode VARCHAR(25) NOT NULL,
	refGuid VARCHAR(50) NOT NULL,
	CONSTRAINT PK_kotProd_ChoiceItems PRIMARY KEY(kotId, rawMCode, sno),
	CONSTRAINT FK_kotProd_ChoiceItems_RawItem FOREIGN KEY (rawMCode) REFERENCES MenuItem (MCODE),
	CONSTRAINT FK_kotProd_ChoiceItems_ParentItem FOREIGN KEY (parentMCode) REFERENCES MenuItem (MCODE)
)