CREATE OR ALTER  VIEW [dbo].[KOTRECORD]
AS
SELECT B.KOTID, A.KOT, A.WAITERNAME,A.TABLENO,A.KOTTIME,A.MCODE,A.QUANTITY,A.UNIT, S.STATUS BILLED,B.TRNDATE,
CASE WHEN S.STATUS = 'BILLED' THEN S.REMARKS ELSE '' END BILLNO,
CASE WHEN S.STATUS = 'TRANSFER' THEN RIGHT(S.REMARKS, LEN(S.REMARKS) - 16) ELSE '' END TRANSFERKOTID,
CASE WHEN S.STATUS = 'MERGE' THEN RIGHT(S.REMARKS, LEN(S.REMARKS) - 10) ELSE '' END MERGEKOTID,
CASE WHEN S.STATUS = 'SPLIT' THEN CASE WHEN LEN(ISNULL(S.REMARKS,'')) >=11 THEN RIGHT(S.REMARKS, LEN(S.REMARKS) - 11) ELSE S.REMARKS END ELSE '' END SPLITKOTID,
CASE WHEN S.STATUS LIKE 'CANCEL%' THEN S.REMARKS ELSE '' END CREMARKS,
CASE WHEN UPPER(ISNULL(A.REMARKS,'')) = 'NO REMARKS' THEN '' ELSE ISNULL(A.REMARKS,'') END RMKS,
NULL CUSER,A.DIVISION FROM RMD_KOTPROD A 
INNER JOIN RMD_KOTMAIN B ON A.KOTID = B.KOTID
INNER JOIN RMD_KOTMAIN_STATUS S ON S.KOTID = B.KOTID