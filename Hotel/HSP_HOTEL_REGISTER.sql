CREATE OR ALTER PROCEDURE HSP_HOTEL_REGISTER
--DECLARE
     @DATE1 DATE ,
	 @DATE2 DATE,
	 @OPT_FLAG VARCHAR(2) = 'BR'
AS
--SELECT @OPT_FLAG = 'CR', @DATE1 = '1 NOV 2023', @DATE2 = '10 NOV 2023'
BEGIN
	
	SET NOCOUNT ON;
	IF @OPT_FLAG='BR'
	BEGIN
		SELECT HB.BookingId,
			   HB.EntryDate,
			   HB.CheckInDate,
			   HB.CheckOutDate,
			   CP.CUSTNAME GuestName,
			   cp.MOBILENO Mobile,
			   cp.IdentityDocument,
			   cp.DocumentNo,
			   hb.Source,
			   hb.ADVANCE,
			   HBS.[STATUS],
			   HB.[USER],
			   HB.Remarks
		FROM HTL_BOOKING HB 
		INNER JOIN HTL_BOOKING_STATUS HBS ON HB.BookingId=HBS.BookingId AND HB.PHISCALID=HBS.PHISCALID 
		LEFT JOIN CustomerProfile CP ON HB.CUSTID=CP.CUSTID
		WHERE HB.EntryDate BETWEEN @DATE1 AND DATEADD(DAY,1, @DATE2)
		ORDER BY HB.EntryDate
    END
	IF @OPT_FLAG='CR'
	BEGIN
		SELECT Hcd.CheckInId,
			   hcd.BookingId,
			   hcd.EntryDate,
			   hcd.CheckInDate,
			   hcd.CheckOutDate,
			   CP.CUSTNAME GuestName,
			   cp.MOBILENO Mobile,
			   cp.IdentityDocument,
			   cp.DocumentNo,
			   hcd.Source,
			   hcd.ADVANCE,
			   hcs.[STATUS],
			   Hcd.[USER],
			   Hcd.Remarks
		FROM  HTL_CHECKIN_DETAILS Hcd 
		INNER JOIN HTL_CHECKIN_STATUS hcs ON hcd.CheckInId=hcs.CheckInId AND hcd.PHISCALID=hcs.PHISCALID 
		LEFT JOIN CustomerProfile CP ON hcd.CUSTID=CP.CUSTID
		WHERE Hcd.EntryDate BETWEEN @DATE1 AND DATEADD(DAY,1, @DATE2)
		ORDER BY Hcd.EntryDate
    END
END