CREATE OR ALTER FUNCTION fnPascalCase(@inputString NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @outputString NVARCHAR(MAX);
	;WITH cte AS (
		SELECT
			ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn,
			value AS word
		FROM STRING_SPLIT(@inputString, ' ')
	)

	SELECT @outputString =
		STRING_AGG(
			UPPER(LEFT(word, 1)) + LOWER(SUBSTRING(word, 2, LEN(word))),
			' '
		) --WITHIN GROUP (ORDER BY rn) PascalCaseString
	FROM cte;
	return @outputString
END

