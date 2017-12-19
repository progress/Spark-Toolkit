/* Load a table include, and register schema. */

&IF DEFINED(OPT) &THEN
{ {&TABLEFILE} OPT={&OPT} }
&ELSE
{ {&TABLEFILE} }
&ENDIF

&IF DEFINED(TABLENAME) &THEN
cast(Ccs.Common.Application:StartupManager:getManager(get-class(Spark.Core.Manager.ISchemaManager)), Spark.Core.Manager.ISchemaManager)
    :registerTempTable(input table {&TABLENAME} by-reference).
&ENDIF
