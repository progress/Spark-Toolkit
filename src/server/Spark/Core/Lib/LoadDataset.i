/* Load a dataset include, and register schema. */

&IF DEFINED(OPT) &THEN
{ {&DATASETFILE} OPT={&OPT} }
&ELSE
{ {&DATASETFILE} }
&ENDIF

&IF DEFINED(DATASETNAME) &THEN
cast(Ccs.Common.Application:StartupManager:getManager(get-class(Spark.Core.Manager.ISchemaManager)), Spark.Core.Manager.ISchemaManager)
    :registerDataset(input dataset {&DATASETNAME} by-reference).
&ENDIF
