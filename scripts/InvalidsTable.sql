DECLARE
   eAlreadyExists Exception;
   pragma exception_init(eAlreadyExists,-00955);
BEGIN
   EXECUTE IMMEDIATE 'CREATE GLOBAL TEMPORARY TABLE DBATools.Invalids ON COMMIT PRESERVE ROWS AS (SELECT Owner, Object_Name, SubObject_Name, Object_ID, Data_object_id, object_type, created, last_ddl_time, timestamp, status, temporary, generated, secondary FROM DBA_Objects WHERE 1=2)';
EXCEPTION
   WHEN eAlreadyExists Then
      NULL;
END;
/


