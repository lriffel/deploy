set heading off
set feedback off
set timing off
set linesize 300
set termout off
spool /tmp/InvalidsToCompile.sql

BEGIN
  --DBMS_Output.Put_Line(' ');
  --DBMS_Output.Put_Line('-----------------------');
  --DBMS_Output.Put('--' || to_char(sysdate,'MM/DD/YYYY HH:MI:SS PM'));
  --DBMS_Output.Put_Line(' - The following objects are newly invalid:');
  For vI In (
        SELECT Object_Type, Owner, Object_Name,
     'ALTER ' || DECODE(Owner,'PUBLIC','PUBLIC ') || REPLACE(Object_Type,' BODY','')
          || DECODE(Owner,'PUBLIC',' ',' "' || Owner || '".') || '"' || Object_Name
          || '" COMPILE ' || DECODE(INSTR(Object_Type,'BODY'),0,'','BODY ') || ';' NewInvalid
        FROM
        (
          SELECT owner, object_type, object_name FROM DBA_OBJECTS WHERE Status = 'INVALID' AND OWNER<>'PUBLIC'
          MINUS
          SELECT owner, object_type, object_name FROM DBATools.Invalids
        )

        ORDER BY owner, object_type, object_name
  ) Loop
    DBMS_Output.Put_Line('set timing off');
    DBMS_Output.Put_Line('prompt ');
    DBMS_Output.Put_Line('prompt Recompiling ' || vI.Object_Type || ' ' || vI.Owner || '.' || vI.Object_Name);
    DBMS_Output.Put_Line('prompt Recompiling using: ' || vI.NewInvalid);
    DBMS_Output.Put_Line(vI.NewInvalid);
    DBMS_Output.Put('SELECT Line, Position, Text ');
    DBMS_Output.Put_Line(' FROM DBA_Errors WHERE Owner=''' || vI.Owner || ''' AND Name=''' || vI.Object_Name || ''';');
    DBMS_Output.Put_Line('set timing on');
  End Loop;
END;
/

spool off
set termout on;
set feedback on
set heading on
