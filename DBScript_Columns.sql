Select C.TABLE_NAME, C.COLUMN_NAME, C.DATA_TYPE, C.CHARACTER_MAXIMUM_LENGTH, C.NUMERIC_PRECISION, C.IS_NULLABLE, TC.CONSTRAINT_NAME
From INFORMATION_SCHEMA.COLUMNS As C
    Left Join INFORMATION_SCHEMA.TABLE_CONSTRAINTS As TC
      On TC.TABLE_SCHEMA = C.TABLE_SCHEMA
          And TC.TABLE_NAME = C.TABLE_NAME
          And TC.CONSTRAINT_TYPE = 'PRIMARY KEY'
Where C.DATA_TYPE = 'varchar' and ISNUMERIC(c.CHARACTER_MAXIMUM_LENGTH) = 1 and c.CHARACTER_MAXIMUM_LENGTH >255


SELECT 
    c.name 'Column Name',
    t.Name 'Data type',
    c.max_length 'Max Length',
    c.precision ,
    c.scale ,
    c.is_nullable,
    ISNULL(i.is_primary_key, 0) 'Primary Key'
FROM    
    sys.columns c
INNER JOIN 
    sys.types t ON c.system_type_id = t.system_type_id
LEFT OUTER JOIN 
    sys.index_columns ic ON ic.object_id = c.object_id AND ic.column_id = c.column_id
LEFT OUTER JOIN 
    sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
WHERE
    c.object_id = OBJECT_ID('YourTableName')