DEFINE VARIABLE hToken AS HANDLE NO-UNDO.
CREATE CLIENT-PRINCIPAL hToken.
hToken:INITIALIZE("dev", STRING(HEX-ENCODE(GENERATE-UUID))).
hToken:DOMAIN-NAME = "bravepoint_com".
hToken:SEAL("bravepoint").
SECURITY-POLICY:LOAD-DOMAINS("Sports2kMT").
SECURITY-POLICY:SET-CLIENT(hToken).
SET-EFFECTIVE-TENANT(0).

DEFINE VARIABLE fileBuffer  AS HANDLE NO-UNDO.
DEFINE VARIABLE tableBuffer AS HANDLE NO-UNDO.
DEFINE VARIABLE hFileQuery  AS HANDLE NO-UNDO.
DEFINE VARIABLE hTableQuery AS HANDLE NO-UNDO.

CREATE BUFFER fileBuffer FOR TABLE "_file".
CREATE QUERY hFileQuery.
hFileQuery:SET-BUFFERS(fileBuffer).
hFileQuery:QUERY-PREPARE("for each _file where _file._hidden ne true and not can-do('web*', _file-name)").
hFileQuery:QUERY-OPEN().

DO WHILE hFileQuery:GET-NEXT(NO-LOCK)
  TRANSACTION:
  CREATE BUFFER tableBuffer FOR TABLE SUBSTITUTE("&1", fileBuffer::_file-name).
  CREATE QUERY hTableQuery.
  hTableQuery:SET-BUFFERS(tableBuffer).
  hTableQuery:QUERY-PREPARE(SUBSTITUTE("for each &1", fileBuffer::_file-name)).
  hTableQuery:QUERY-OPEN().

  DO WHILE hFileQuery:GET-NEXT(EXCLUSIVE-LOCK)
  TRANSACTION:
    {&OUT} tableBuffer:NAME "<br/>".
    tableBuffer:BUFFER-DELETE().
  END.

  DELETE OBJECT tableBuffer NO-ERROR.
  DELETE OBJECT hTableQuery NO-ERROR.
END.

FINALLY:
  hToken:LOGOUT().
  DELETE OBJECT hToken NO-ERROR.
  DELETE OBJECT hFileQuery NO-ERROR.
END FINALLY.