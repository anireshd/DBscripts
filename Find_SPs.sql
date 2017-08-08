--select * from syscomments where text like '%xpPerformance_Pre05%'

--select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_DEFINITION LIKE '%xpPerformance_Pre05%'

--SELECT ROUTINE_NAME, ROUTINE_DEFINITION 
--    FROM INFORMATION_SCHEMA.ROUTINES 
--    WHERE ROUTINE_DEFINITION LIKE '%xpPerformance_Pre05%' 
--    AND ROUTINE_TYPE='PROCEDURE'
    
    
-- Search in All Objects
SELECT OBJECT_NAME(OBJECT_ID),
definition
FROM sys.sql_modules
WHERE definition LIKE '%' + 'BusinessEntityID' + '%'
GO


-- Search in Stored Procedure Only
SELECT DISTINCT OBJECT_NAME(OBJECT_ID),
object_definition(OBJECT_ID)
FROM sys.Procedures
WHERE object_definition(OBJECT_ID) LIKE '%' + 'BusinessEntityID' + '%'
GO