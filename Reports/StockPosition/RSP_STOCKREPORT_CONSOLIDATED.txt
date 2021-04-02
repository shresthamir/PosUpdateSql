CREATE OR ALTER   PROCEDURE [dbo].[RSP_STOCKREPORT_CONSOLIDATED] 
	@DATE1 DATETIME,
	@DATE2 DATETIME,
	@WAREHOUSE VARCHAR(100) ='%',
	@MENUCAT VARCHAR(100) ='%',
	@SUPPLIER_ACID VARCHAR(20)='%',
	@MGROUP VARCHAR(20) = '%',
	@PTYPE INT='100',
	@PATH NVARCHAR(4000)='%',
	@CHK_BarcodeWise TINYINT =0,                        --CHK_BarcodeWise:1:0
	@OPT_WISE VARCHAR(50) = 'ITEM',            			--Mgroup:Mgroup,Item:Item,MCat:MCat
	@MCODE varchar(25) = '%',
	@barcode VARCHAR(25) = '%',
	@DIVISION VARCHAR(3)= '%',
	@OPT_RepMode tinyint = 0,					--All:0,NonZero:1,NegativeOnly:2,ZeroOnly:3
	@OPT_TREE tinyint = 0,                                          --NonTree:0,Tree:1
	@OPT_FIFO TINYINT = 0,                      ----FIFO:1,LatestMRP:0
	@GROUP VARCHAR(25)='MI',
	@DOVALUATION TINYINT = 0,
	@CHK_GRNWise TINYINT = 0,                     --CHK_GRNWise:1:0   
	@FYID VARCHAR(20) = '%'
AS
IF @OPT_FIFO = 1 
	SET @DOVALUATION = 1
EXEC NSP_STOCKREPORT_CONSOLIDATED	@DATE1 =@DATE1,
	@DATE2 =@DATE2,
	@WAREHOUSE =@WAREHOUSE ,
	@CATEGORY =@MENUCAT  ,
	@SUPPLIER =@SUPPLIER_ACID  ,
	@ITEMGROUP =@MGROUP  ,
	@PTYPE =@PTYPE ,
	@PATH =@PATH ,
	@BYBARCODE =@CHK_BarcodeWise,
	@WISE =@OPT_WISE ,      
	@ItemCode =@MCODE ,
	@barcode =@barcode ,
	@DIVISION =@DIVISION ,
	@RepMode =@OPT_RepMode ,
	@TreeFormat =@OPT_TREE ,
	@SHOWVALUATIONRATE =@OPT_FIFO ,
	@GROUP =@GROUP ,
	@DOVALUATION =@DOVALUATION,
	@GRNWise=@CHK_GRNWise,
	@FYID = @FYID
