CREATE OR ALTER FUNCTION dbo.Compare_JsonObject (@SourceJSON NVARCHAR(MAX), @TargetJSON NVARCHAR(MAX), @KeyFields VARCHAR(200))
/**
Summary: >
  This function 'diffs' a source JSON document with a target JSON document and produces an
  analysis of which properties are missing in either the source or target, or the values
  of these properties that are different. It reports on the properties and values for 
  both source and target as well as the path that references that scalar value. The 
  path reference to the object's parent is exposed in the result to enable a query to
  reference the value of any other object in the parent that is needed. 
Author: Phil Factor
Date: 06/07/2020
Revised:
	- mod: Added the parent reference to the difference report
	- Date: 09/07/2020
Database: PhilsRoutines
Examples:
   - SELECT * FROM dbo.Compare_JsonObject(@TheSourceJSON, @TheTargetJSON)
       WHERE SideIndicator <> '==';
   - SELECT *, Json_Value(@TheSourceJSON,TheParent+'.name')
       FROM dbo.Compare_JsonObject(@TheSourceJSON, @TheTargetJSON)
       WHERE SideIndicator <> '==';
Returns: >
  SideIndicator:  ( == equal, <- not in target, ->  not in source, <> not equal
  ThePath:   the JSON path used by the SQL JSON functions 
  TheKey:  the key field without the path
  TheSourceValue: the value IN the SOURCE JSON document
  TheTargetValue: the value IN the TARGET JSON document
 
**/

RETURNS 
--Declare @KeyFields VARCHAR(200) = (SELECT KeyFielD FROM vwTableKeys where TableName = 'Discount_Rate')
--DECLARE 
@returntable TABLE
  (
  SideIndicator CHAR(2), -- == means equal, <- means not in target, -> means not in source, <> means not equal
  TheParent  NVARCHAR(2000), --the parent object
  ThePath NVARCHAR(2000), -- the JSON path used by the SQL JSON functions 
  TheKey NVARCHAR(200), --the key field without the path
  TheSourceValue NVARCHAR(200), -- the value IN the SOURCE JSON document
  TheTargetValue NVARCHAR(200), -- the value IN the TARGET JSON document
  KeyValue NVARCHAR(200), --Edited row key value 
  TrnUser VARCHAR(100)
  )
AS
/*
	--DECLARE @KEY VARCHAR(100) = 'DisID'
	DECLARE @SourceJSON NVARCHAR(MAX), @TargetJSON NVARCHAR(MAX)
  SET @SOURCEJSON = '[{"DisID":33,"Mgroup":"PRG10822","DisRate":10.50,"DisAmount":0.0000000000000000,"ReceipeID":0,"Priority":0,"CardPriority":0,"ScheduleID":11,"SchemeName":"MySchemeTestMgroupJan10","GreaterThan":0.0000000000000000,"LessThan":0.0000000000000000,"Quantity":0,"DiscountQuantity":0,"SchemeType":"mgroup","VAT":0,"edate":"2023-01-10T00:00:00","Trndate":"2023-01-10T00:00:00","IsActive":1,"Divisions":"MMK,MMD,MMH,MMM,MML","IsIndividual":0,"STAMP":4.493454599930556e+004,"MaxDiscount":0.00,"TRNUSER":"Admin"}]'

  SET @TargetJSON = '[{"DisID":33,"Mgroup":"PRG10822","DisRate":10.00,"DisAmount":0.0000000000000000,"ReceipeID":0,"Priority":0,"CardPriority":0,"ScheduleID":11,"SchemeName":"MySchemeTestMgroupJan10","GreaterThan":0.0000000000000000,"LessThan":0.0000000000000000,"Quantity":0,"DiscountQuantity":0,"SchemeType":"mgroup","VAT":0,"edate":"2023-01-10T00:00:00","Trndate":"2023-01-10T00:00:00","IsActive":1,"Divisions":"MMK,MMD,MMH,MMM,MML","IsIndividual":0,"STAMP":4.493454599930556e+004,"MaxDiscount":0.00,"TRNUSER":"Admin"}]'

  --select * from openjson(@targetjson)
    */
  BEGIN
    IF (IsJson(@SourceJSON) = 1 AND IsJson(@TargetJSON) = 1) --don't try anything if either json is invalid
      BEGIN
        DECLARE @map TABLE --these contain all properties or array elements with scalar values
          (
          iteration INT, --the number of times that more arrays or objects were found
          SourceOrTarget CHAR(1), --is this the source 's' OR the target 't'
 		  TheParent NVARCHAR(80), --the parent object
		  ThePath NVARCHAR(80), -- the JSON path to the key/value pair or array element
          TheKey NVARCHAR(2000), --the key to the property
          TheValue NVARCHAR(MAX),-- the value
          TheType INT --the type of value it is
          );
        DECLARE @objects TABLE --this contains all the properties with arrays and objects 
          (
          iteration INT,
          SourceOrTarget CHAR(1),
		  TheParent NVARCHAR(80),
          ThePath NVARCHAR(80),
          TheKey NVARCHAR(2000),
          TheValue NVARCHAR(MAX),
          TheType INT
          );
        DECLARE @depth INT = 1; --we start in shallow water
        DECLARE @HowManyObjectsNext INT = 1, @SourceType INT, @TargetType INT;
        SELECT --firstly, we try to work out if the source is an array or object
          @SourceType = 
            CASE IsNumeric((SELECT TOP 1 [key] FROM OpenJson(@SourceJSON))) 
              WHEN 1 THEN 4 ELSE 5 END,
          @TargetType= --and if the target is an array or object
            CASE IsNumeric((SELECT TOP 1 [key] FROM OpenJson(@TargetJSON))) 
              WHEN 1 THEN 4 ELSE 5 END
        --now we insert the base objects or arrays into the object table      
        INSERT INTO @objects 
          (iteration, SourceOrTarget, TheParent, ThePath, TheKey, TheValue, TheType)
          SELECT 0, 's' AS SourceOrTarget,'' AS parent, '$' AS path, '', @SourceJSON, @SourceType;
        INSERT INTO @objects 
          (iteration, SourceOrTarget,TheParent, ThePath, TheKey, TheValue, TheType)
          SELECT 0, 't' AS SourceOrTarget, '' AS parent, '$' AS path,
          '', @TargetJSON, @TargetType;
      --we now set the depth and how many objects are in the next iteration
        SELECT @depth = 0, @HowManyObjectsNext = 2; 
        WHILE @HowManyObjectsNext > 0
          BEGIN
            INSERT INTO @map --get the scalar values into the @map table
              (iteration, SourceOrTarget, TheParent, ThePath, TheKey, TheValue, TheType)
              SELECT -- 
                o.iteration + 1, SourceOrTarget,
				ThePath,
                ThePath+CASE Thetype WHEN 4 THEN '['+[Key]+']' ELSE '.'+[key] END, 
                [key],[value],[type]
                FROM @objects AS o
                  CROSS APPLY OpenJson(TheValue)
                WHERE Type IN (1, 2, 3) AND o.iteration = @depth;
			--now we do the same for the objects and arrays
            INSERT INTO @objects (iteration, SourceOrTarget, TheParent, ThePath, TheKey,
            TheValue, TheType)
              SELECT o.iteration + 1, SourceOrTarget,ThePath,
               ThePath + CASE TheType WHEN 4 THEN '['+[Key]+']' ELSE '.'+[Key] END,
               [key],[value],[type]
              FROM @objects o 
			  CROSS APPLY OpenJson(TheValue)
			  WHERE [type] IN (
			  4,5) AND o.iteration=@depth    
           SELECT @HowManyObjectsNext=@@RowCount --how many objects or arrays?
           SELECT @depth=@depth+1 --and so to the next depth maybe
         END
		-- SELECT * FROM @MAP
		 --SELECT * FROM @OBJECTS
--now we just do a full join on the columns we are comparing and work out the comparison
         INSERT INTO @returntable
          SELECT 
		   --first we work out the side-indicator that summarises the comparison
           CASE WHEN The_Source.TheValue=The_Target.TheValue THEN '=='
             ELSE 
             CASE  WHEN The_Source.ThePath IS NULL THEN '-' ELSE '<' end
               + CASE WHEN The_Target.ThePath IS NULL THEN '-' ELSE '>' END 
           END AS Sideindicator, 
		   --these columns could be in either table
		   Coalesce(The_source.TheParent, The_target.TheParent) AS TheParent,
           Coalesce(The_source.ThePath, The_target.ThePath) AS TheactualPath,
           Coalesce(The_source.TheKey, The_target.TheKey) AS TheKey,
           The_source.TheValue, The_target.TheValue, NULL,Null
            FROM 
               (SELECT TheParent, ThePath, TheKey, TheValue FROM @map WHERE SourceOrTarget = 's')
			     AS The_source -- the source scalar literals
              FULL OUTER JOIN 
               (SELECT TheParent, ThePath, TheKey, TheValue FROM @map WHERE SourceOrTarget = 't')
			     AS The_target --the target scalar literals
                ON The_source.ThePath = The_target.ThePath
            ORDER BY TheactualPath;
      END;

	  --SELECT TheParent, STRING_AGG(IIF(ISNULL(b.THESOURCEVALUE,'') = '', b.THETARGETVALUE, b.thesourcevalue), '-') FROM @returnTable b WHERE theKey IN ( 'MCODE', 'BCODE') GROUP BY TheParent
	  UPDATE A SET A.TrnUser =  B.TrnUser  from   @returnTable A JOIN 
	  (
        SELECT  TheValue TrnUser,TheParent FROM @map b WHERE theKey IN ('TRNUSER','LOGGEDINUSER') AND SourceOrTarget = 's'
	  ) B  ON A.TheParent = B.TheParent

	  UPDATE A SET A.[KeyValue] = b.[KeyValue] FROM @returnTable A JOIN 
	  (
        SELECT TheParent, STRING_AGG(IIF(ISNULL(b.THESOURCEVALUE,'') = '', b.THETARGETVALUE, b.thesourcevalue), '-') KeyValue FROM @returnTable b 
		WHERE theKey IN ( SELECT * FROM SPLIT(@KeyFields, ',')) GROUP BY TheParent
	  ) B ON A.TheParent = B.TheParent
	  --select * from @returntable
   RETURN;
  END;