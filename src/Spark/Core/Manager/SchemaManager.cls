 /*------------------------------------------------------------------------
    File        : SchemaManager
    Purpose     :
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Fri Dec 19 14:31:04 EST 2014
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Spark.Core.Manager.ILoggingManager from propath.
using Spark.Core.Util.MethodSignature from propath.
using Spark.Core.Util.OSTools from propath.
using Spark.Core.Util.Strings from propath.

block-level on error undo, throw.

class Spark.Core.Manager.SchemaManager inherits Spark.Core.Manager.Manager implements Spark.Core.Manager.ISchemaManager:

    define protected property oLoggingManager as ILoggingManager no-undo
        get:
            if not valid-object(oLoggingManager) then
                assign oLoggingManager = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ILoggingManager)), ILoggingManager).
            return oLoggingManager.
        end get.
        set.


    define protected temp-table SchemaObject no-undo
        field ObjectParent  as character
        field ObjectName    as character
        field ObjectAltName as character
        field ObjectSchema  as CLOB
        field ObjectHandle  as handle
        field ObjectType    as character
        index idxPrimary    is primary unique ObjectParent ObjectName
        .

    define protected temp-table ConfigDB no-undo serialize-name "Databases"
        field DatabaseName  as character /* Logical name of connected database. */
        field DomainMaster  as logical   /* Denotes that database is domain authority. */
        field Include       as logical   /* Denotes that database should be included. */
        field IncludeTable  as character /* can-do compatible list of tables to include. */
        field ExcludeTable  as character /* can-do compatible list of tables to exclude. */
        field SearchTable   as character /* can-do compatible list of tables to search. */
        field DebugSchema   as logical   /* Output debug statements during schema registration. */
        field IsMultiTenant as logical   /* RESERVED: Set at runtime to denote multi-tenant DB. */
        index pkDBName      is primary unique DatabaseName
        .

    define protected temp-table ConfigTable no-undo serialize-name "Tables"
        field DatabaseName  as character /* Logical name of connected database. */
        field TableName     as character /* Standard name of target table. */
        field AltTableName  as character /* JSON-safe name of target table. */
        field Include       as logical   /* Denotes that table should be included. */
        field IncludeField  as character /* can-do compatible list of fields to include. */
        field ExcludeField  as character /* can-do compatible list of fields to exclude. */
        field Mode          as character /* If "explicit" IncludeField or ExcludeField must be used. */
        field PrimaryKeys   as character /* List of derived primary keys. */
        index pkDBTable     is primary unique DatabaseName TableName
        .

    define protected temp-table ConfigField no-undo serialize-name "Fields"
        field DatabaseName   as character /* Logical name of connected database. */
        field TableName      as character /* Standard name of target table. */
        field FieldName      as character /* Standard name of target field. */
        field AltFieldName   as character /* JSON-safe name of target table. */
        field FieldLabel     as character /* Default title to use for field. */
        field Include        as logical   /* Denotes that field should be included. */
        field DataType       as character /* Datatype of field (ABL type). */
        field ExtentCount    as integer   /* Number of extents on field, if any. */
        field ViewTasks      as character /* Tasks that allow viewing of the field. */
        field EditTasks      as character /* Tasks that allow editing of the field. */
        index pkDBTableField is primary unique DatabaseName TableName FieldName
        .

    define protected dataset dsConfig serialize-name "Config"
        for ConfigDB, ConfigTable, ConfigField.


    method protected logical addSchemaToSignature ( input pcObjectList      as character,
                                                    input poMethodSignature as MethodSignature ):
        define variable iCount        as integer  no-undo.
        define variable cObjectSchema as longchar no-undo.

        do iCount = 1 to num-entries(pcObjectList):
            for first SchemaObject no-lock
                where SchemaObject.ObjectName eq entry(iCount, pcObjectList):
                cObjectSchema = SchemaObject.ObjectSchema.
                poMethodSignature:setParameterSchema( input SchemaObject.ObjectName,
                                                      input cObjectSchema ).
            end.
        end.
    end method.


    method protected void examineDatabases ( ):
        define variable iDB as integer no-undo.

        DATABASEBLK:
        do iDB = 1 to num-dbs on error undo, throw:
            find first ConfigDB where ConfigDB.DatabaseName eq ldbname(iDB) no-error.
            /* Not found or explicitly excluded in config file. */
            if not available(ConfigDB) or not ConfigDB.Include then next DATABASEBLK.

            this-object:examineTables(ldbname(iDB),
                                      ConfigDB.IncludeTable,
                                      ConfigDB.ExcludeTable,
                                      ConfigDB.DebugSchema).

            catch err as Progress.Lang.Error:
                message substitute("Error while registering database: &1", err:GetMessage(1)).
                undo, throw err.
            end catch.
        end.
    end method. /* examineDatabases */


    method protected void examineTables ( input pcDatabaseName as character ):
        this-object:examineTables(pcDatabaseName, "", "", false).
    end method. /* examineTables */


    method protected void examineTables ( input pcDatabaseName  as character,
                                          input pcIncludeTables as character,
                                          input pcExcludeTables as character,
                                          input plUseDebugs     as logical ):
        define variable iExtent     as integer   no-undo.
        define variable iField      as integer   no-undo.
        define variable iKey        as integer   no-undo.
        define variable fileBuffer  as handle    no-undo.
        define variable fieldBuffer as handle    no-undo.
        define variable fieldHandle as handle    no-undo.
        define variable tempTable   as handle    no-undo.
        define variable hFileQuery  as handle    no-undo.
        define variable cFieldList  as character no-undo.
        define variable cFieldName  as character no-undo.
        define variable cFieldTitle as character no-undo.
        define variable cKeyField   as character no-undo.
        define variable cTableName  as character no-undo.

        if (pcDatabaseName gt "") ne true then return.

        create buffer fileBuffer for table substitute("&1._file", pcDatabaseName).

        create query hFileQuery.
        hFileQuery:set-buffers(fileBuffer).
        hFileQuery:query-prepare(substitute("for each &1 where &1._Hidden ne true", fileBuffer:name)).
        hFileQuery:query-open().

        /* Cycle through each table in this database. */
        TABLEBLK:
        do while hFileQuery:get-next() on error undo, throw:
            assign
                cFieldList = "" /* Reset the field list for each table. */
                cTableName = fileBuffer::_file-name
                .

            /* Check for an existing ConfigTable entry for the current database table. */
            find first ConfigTable exclusive-lock
                 where ConfigTable.DatabaseName eq pcDatabaseName
                   and ConfigTable.TableName eq cTableName no-error.

            /* Either use the given ConfigTable entry or create new with defaults. */
            if available ConfigTable then do on error undo, throw:
                if not ConfigTable.Include then next TABLEBLK. /* Explicitly excluded in config. */
                if (ConfigTable.AltTableName gt "") ne true then
                    assign ConfigTable.AltTableName = "tt" + Strings:stripBadChars(cTableName).
            end. /* AVAILABLE ConfigTable */
            else do on error undo, throw:
                create ConfigTable.
                assign
                    ConfigTable.DatabaseName = pcDatabaseName
                    ConfigTable.TableName    = cTableName
                    ConfigTable.AltTableName = "tt" + Strings:stripBadChars(cTableName)
                    ConfigTable.Include      = true
                    ConfigTable.IncludeField = "*"
                    ConfigTable.ExcludeField = ""
                    ConfigTable.Mode         = "implied"
                    .
            end. /* NOT AVAILABLE ConfigTable */

            /* List of included tables has been provided, and table is not in list. */
            if (pcIncludeTables gt "") eq true
                and not can-do(pcIncludeTables, cTableName)
                then assign ConfigTable.Include = false.

            /* List of excluded tables has been provided, and table is in list. */
            if (pcExcludeTables gt "") eq true
                and can-do(pcExcludeTables, cTableName)
                then assign ConfigTable.Include = false.

            /* Skip the table if not configured to be included. */
            if not ConfigTable.Include then next TABLEBLK.

            /* Create a buffer against this database table. */
            create buffer fieldBuffer for table substitute("&1.&2", pcDatabaseName, cTableName).

            /* Create a "clean" temp-table to register later. */
            create temp-table tempTable.

            /* Add fields for rowid and unique sequence. */
            tempTable:add-new-field("id", "character").
            tempTable:add-new-field("seq", "integer").

            /* Cycle through all fields for this table. */
            FIELDBLK:
            do iField = 1 to fieldBuffer:num-fields on error undo, throw:
                assign
                    fieldHandle = fieldBuffer:buffer-field(iField)
                    cFieldList  = trim(substitute("&1,&2", cFieldList, fieldHandle:name), ",")
                    cFieldName  = Strings:stripBadChars(fieldHandle:name)
                    .

                find first ConfigField exclusive-lock
                     where ConfigField.DatabaseName eq pcDatabaseName
                       and ConfigField.TableName eq cTableName
                       and ConfigField.FieldName eq fieldHandle:name no-error.
                /* Either use the given ConfigField entry or create new with defaults. */
                if available ConfigField then do on error undo, throw:
                    if not ConfigField.Include then next FIELDBLK. /* Explicitly excluded in config. */
                end. /* ConfigField has explicit instructions regarding this field. */
                else do on error undo, throw:
                    create ConfigField.
                    assign
                        ConfigField.DatabaseName = pcDatabaseName
                        ConfigField.TableName    = cTableName
                        ConfigField.FieldName    = fieldHandle:name
                        ConfigField.Include      = true
                        ConfigField.DataType     = caps(fieldHandle:data-type)
                        ConfigField.ExtentCount  = fieldBuffer:buffer-field(iField):extent
                        ConfigField.ViewTasks    = "" /* Allow any task to view. */
                        ConfigField.EditTasks    = "" /* Allow any task to edit. */
                        .
                end. /* NOT AVAILABLE ConfigField */

                /* List of included fields has been provided, and field is not in list. */
                if (ConfigTable.IncludeField gt "") eq true
                    and not can-do(ConfigTable.IncludeField, ConfigField.FieldName)
                    then assign ConfigField.Include = false.

                /* List of excluded fields has been provided, and field is in list. */
                if (ConfigTable.ExcludeField gt "") eq true
                    and can-do(ConfigTable.ExcludeField, ConfigField.FieldName)
                    then assign ConfigField.Include = false.

                /* Skip the field if not configured to be included. */
                if not ConfigField.Include then next FIELDBLK.

                /* In explicit mode, all fields must either be included or excluded explicitly. */
                if ConfigTable.Mode eq "explicit" then next FIELDBLK.

                if (ConfigField.AltFieldName gt "") ne true then
                    assign ConfigField.AltFieldName = Strings:stripBadChars(fieldHandle:name).
                if (ConfigField.FieldLabel gt "") ne true then
                    assign ConfigField.FieldLabel = Strings:stripBadChars(fieldHandle:label).
                if (ConfigField.DataType gt "") ne true then
                    assign ConfigField.DataType = caps(fieldHandle:data-type).

                /* Populate dynamic temp-table with safe field names (using label/col-label as special buckets). */
                /* In addition, if there is an extent involved, create a new field for each extent position. */
                if fieldBuffer:buffer-field(iField):extent gt 0 then
                do iExtent = 1 to fieldBuffer:buffer-field(iField):extent on error undo, throw:
                    tempTable:add-new-field(ConfigField.AltFieldName + "_" + string(iExtent),
                                            ConfigField.DataType,
                                            ?,
                                            ?,
                                            ?,
                                            ConfigField.FieldLabel + " " + string(iExtent),
                                            ConfigField.FieldName).
                end.
                else /* Not an extent field, add normally. */
                    tempTable:add-new-field(ConfigField.AltFieldName,
                                            ConfigField.DataType,
                                            ?,
                                            ?,
                                            ?,
                                            ConfigField.FieldLabel,
                                            ConfigField.FieldName).

                release ConfigField.

                catch err as Progress.Lang.Error:
                    message substitute("Error while registering table fields: &1", err:GetMessage(1)).
                    undo, throw err.
                end catch.
            end. /* FIELDBLK */

            /* Deal with any extra fields added in the XML Config that were not in the DB schema. */
            EXTRAFIELDBLK:
            for each ConfigField exclusive-lock
               where ConfigField.DatabaseName eq pcDatabaseName
                 and ConfigField.TableName eq cTableName
                 and ConfigField.Include
                 and not can-do(cFieldList, ConfigField.FieldName) on error undo, throw:
                if (ConfigField.FieldLabel gt "") ne true then
                    assign ConfigField.FieldLabel = ConfigField.FieldName.

                if ConfigField.ExtentCount gt 0 then
                do iExtent = 1 to ConfigField.ExtentCount on error undo, throw:
                    tempTable:add-new-field(ConfigField.FieldName + "_" + STRING(iExtent),
                                            ConfigField.DataType,
                                            ?,
                                            ?,
                                            ?,
                                            ConfigField.FieldLabel + " " + STRING(iExtent),
                                            "").
                end.
                else /* Not an extent field, add normally. */
                    tempTable:add-new-field(ConfigField.FieldName,
                                            ConfigField.DataType,
                                            ?,
                                            ?,
                                            ?,
                                            ConfigField.FieldLabel,
                                            "").

                catch err as Progress.Lang.Error:
                    message substitute("Error while registering extra fields: &1", err:GetMessage(1)).
                    undo, throw err.
                end catch.
            end. /* extraFieldblk */

            /* Generate an index based on keys from the original table. */
            INDEXBLK:
            do on error undo, throw:
                tempTable:add-new-index("puSeq", true, true).
                tempTable:add-index-field("puSeq", "seq").

                if fieldBuffer:keys ne "rowid" then
                do iKey = 1 to num-entries(fieldBuffer:keys) on error undo, throw:
                    if iKey eq 1 then tempTable:add-new-index("idxUnique", true).
                    assign cKeyField = Strings:stripBadChars(entry(iKey, fieldBuffer:keys)).
                    ConfigTable.PrimaryKeys = trim(substitute("&1,&2.&3", ConfigTable.PrimaryKeys, ConfigTable.AltTableName, cKeyField), ",").
                    tempTable:add-index-field("idxUnique", cKeyField).
                end. /* if keys */

                catch err as Progress.Lang.Error:
                    message substitute("Error while registering index for &1: &2", cTableName, err:GetMessage(1)).
                    undo, throw err.
                end catch.
            end. /* INDEXBLK */

            /* Create and register the "clean" temp-table with the schema manager. */
            tempTable:temp-table-prepare(ConfigTable.AltTableName).
            this-object:registerTempTable(input tempTable).

            release ConfigTable.

            catch err as Progress.Lang.Error:
                message substitute("Error while registering table &1: &2", cTableName, err:GetMessage(1)).
                undo, throw err.
            end catch.

            finally:
                delete object fieldBuffer no-error.
                delete object fieldHandle no-error.
            end finally.
        end. /* TABLEBLK */

        catch err as Progress.Lang.Error:
            message substitute("Table preparation error: &1", err:GetMessage(1)).
            undo, throw err.
        end catch.
        finally:
            if valid-handle(hFileQuery) then
                hFileQuery:query-close().
            delete object hFileQuery no-error.
            delete object fileBuffer no-error.
        end finally.
    end method. /* examineTables */


    method protected void registerDatabases ( ):
        define variable cFullCfgFileName as character no-undo.
        file-info:file-name = OSTools:sparkConf + "schema.json".
        cFullCfgFileName = file-info:full-pathname.
        if cFullCfgFileName ne ? then do:
            dataset dsConfig:read-json("FILE", cFullCfgFileName, "EMPTY").

            /* Register all databases according to the config file. */
            if num-dbs ge 1 and can-find(first ConfigDB no-lock) then
                this-object:examineDatabases().
        end. /* has config */
        else if log-manager:logging-level ge 3 then
            /* It is not necessary to have a config for this manager, but let's output a notice when logging level is elevated. */
            message substitute("Notice: Schema config file [schema.json] not found in [&1], using defaults.", OSTools:sparkConf).
    end method. /* registerDatabases */


    /**************************** Public Helper Methods ****************************/


    method public static void fixSerializedNames ( input table-handle phTableHandle ):
        define variable hBuffer as handle  no-undo.
        define variable hField  as handle  no-undo.
        define variable iCount  as integer no-undo.

        if not valid-handle(phTableHandle) then return.

        /* There is a "bug" in the XML-SCHEMA logic that does not separately store
         * the SERIALIZE-NAME attribute for fields as the XML-NODE-NAME. Therefore,
         * we must manually restore that property from the latter.
         */
        assign hBuffer = phTableHandle:default-buffer-handle.
        do iCount = 1 to hBuffer:num-fields:
            assign hField = hBuffer:buffer-field(iCount) NO-ERROR.
            if valid-handle(hField) then
                assign hField:serialize-name = hField:xml-node-name.
        end.

        /* Additionally, if the table name differs from the node name,
         * set the serialize-name property of the table accordingly.
         */
        if (phTableHandle:xml-node-name gt "") eq true and
           phTableHandle:name ne phTableHandle:xml-node-name then
            assign phTableHandle:serialize-name = phTableHandle:xml-node-name.
    end method. /* fixSerializedNames */


    method public void deleteObjects ( ):
        for each SchemaObject exclusive-lock:
            delete object SchemaObject.ObjectHandle no-error.
            delete SchemaObject.
        end. /* for each */
    end method. /* deleteObjects */


    method public void dumpObjects ( ):
        temp-table SchemaObject:write-json("file", substitute("&1/SchemaInfo.json", right-trim(replace(session:temp-directory, "~\", "~/"), "~/")), true).

        catch err as Progress.Lang.Error:
            /* Do not throw errors on a debug action, just message out and continue. */
            message substitute("Error while dumping schema: &1", err:GetMessage(1)).
        end catch.
    end method. /* dumpObjects */


    method override public void initialize ( ):
        this-object:registerDatabases().
    end method. /* initialize */


    method override public void dispose ( ):
    end method.


    method public void getObject ( input  pcParentName    as character,
                                   input  pcObjectName    as character,
                                   output pcObjectAltName as character,
                                   output pcObjectType    as character,
                                   output pcObjectSchema  as longchar ):
        for first SchemaObject no-lock
            where SchemaObject.ObjectParent eq pcParentname
              and SchemaObject.ObjectName eq pcObjectName:
            assign
                pcObjectAltName = SchemaObject.ObjectAltName
                pcObjectType    = SchemaObject.ObjectType
                pcObjectSchema  = SchemaObject.ObjectSchema
                .
        end.
    end method. /* getObject */


    method public void getObjectChildren ( input  pcParentName as character,
                                           output pcObjectList as character ):
        for each SchemaObject no-lock
           where SchemaObject.ObjectParent eq pcParentName:
            assign pcObjectList = substitute("&1,&2", pcObjectList, SchemaObject.ObjectName).
        end.

        assign pcObjectList = trim(pcObjectList, ",").

        oLoggingManager:logMessage(substitute("Found children '&1' for parent '&2'",
                                              pcObjectList,
                                              pcParentName), "SPARK-SCHM", 6).
    end method. /* getObjectChildren */


    method public void getObjectList ( input  pcSchemaType as character,
                                       output pcObjectList as character ):
        if (pcSchemaType gt "") eq true then
            for each SchemaObject no-lock
               where SchemaObject.ObjectType eq pcSchemaType:
                assign pcObjectList = substitute("&1,&2", pcObjectList, SchemaObject.ObjectName).
            end.
        else
            for each SchemaObject no-lock:
                assign pcObjectList = substitute("&1,&2", pcObjectList, SchemaObject.ObjectName).
            end.

        assign pcObjectList = trim(pcObjectList, ",").

        oLoggingManager:logMessage(substitute("Found object(s) '&1' for schema type '&2'",
                                              pcObjectList,
                                              pcSchemaType), "SPARK-SCHM", 6).
    end method. /* getObjectList */


    method public logical getDataset ( input  pcDatasetName as character,
                                       output dataset-handle phDatasetHandle ):
        define variable cObjectAltName as character no-undo.
        define variable cObjectType    as character no-undo.
        define variable cDatasetSchema as longchar  no-undo.

        this-object:getObject("", pcDatasetName, output cObjectAltName, output cObjectType, output cDatasetSchema).
        if cObjectType eq "dataset" then do:
            create dataset phDatasetHandle.
            return this-object:getDataset(cDatasetSchema, output dataset-handle phDatasetHandle by-reference).
        end.

        return false.

        finally:
            delete object phDatasetHandle no-error.
        end finally.
    end method. /* getDataset */


    method public logical getDataset ( input  plcDatasetSchema as longchar,
                                       output dataset-handle phDatasetHandle ):
        define variable hTableHandle as handle  no-undo.
        define variable iCount       as integer no-undo.

        if (plcDatasetSchema gt "") eq true and valid-handle(phDatasetHandle) then do:
            phDatasetHandle:read-xmlschema("longchar", plcDatasetSchema, false).

            /* If the dataset name differs from the node name, set
             * the serialize-name property of the table accordingly.
             */
            if (phDatasetHandle:xml-node-name gt "") eq true and
               phDatasetHandle:name ne phDatasetHandle:xml-node-name then
                assign phDatasetHandle:serialize-name = phDatasetHandle:xml-node-name.

            do iCount = 1 to phDatasetHandle:num-buffers:
                assign hTableHandle = phDatasetHandle:get-buffer-handle(iCount):table-handle.
                Spark.Core.Manager.SchemaManager:fixSerializedNames(input table-handle hTableHandle by-reference).
            end.

            return true.
        end.

        return false.
    end method. /* getDataset */


    method public logical getTempTable ( input  pcTableName as character,
                                         output table-handle phTableHandle ):
        define variable cObjectAltName as character no-undo.
        define variable cObjectType    as character no-undo.
        define variable cTableSchema   as longchar  no-undo.

        getObject("", pcTableName, output cObjectAltName, output cObjectType, output cTableSchema).
        if cObjectType eq "temp-table" then do:
            create temp-table phTableHandle.
            phTableHandle:read-xmlschema("longchar", cTableSchema, false).
            Spark.Core.Manager.SchemaManager:fixSerializedNames(input table-handle phTableHandle by-reference).
            return true.
        end.

        return false.

        finally:
            delete object phTableHandle no-error.
        end finally.
    end method. /* getTempTable */


    method public void initMethodSignature ( input poMethodSignature as MethodSignature ):
        if valid-object(poMethodSignature) then do:
            this-object:addSchemaToSignature(poMethodSignature:getDatasets(), poMethodSignature).
            this-object:addSchemaToSignature(poMethodSignature:getTempTables(), poMethodSignature).
        end.
    end method. /* initMethodSignature */


    method public void initSchema ( ):
        for each SchemaObject no-lock
           where valid-handle(SchemaObject.ObjectHandle):
            case SchemaObject.ObjectHandle:type:
                when "dataset" then
                    SchemaObject.ObjectHandle:empty-dataset().
                when "temp-table" then
                    SchemaObject.ObjectHandle:default-buffer-handle:empty-temp-table().
            end case.
        end.
    end method. /* initSchema */


    method public void registerDataset ( input phDatasetHandle as handle ):
        define variable iCount        as integer  no-undo.
        define variable hTableHandle  as handle   no-undo.
        define variable cObjectSchema as longchar no-undo.

        if not valid-handle(phDatasetHandle) then return.

        phDatasetHandle:write-xmlschema("longchar", cObjectSchema) no-error.
        if error-status:error then
            undo, throw new AppError(substitute("Error registering dataset '&1'", phDatasetHandle:name), -1).

        find first SchemaObject exclusive-lock
             where SchemaObject.ObjectParent eq ""
               and SchemaObject.ObjectName eq phDatasetHandle:name no-error.

        if not available(SchemaObject) then do:
            create SchemaObject.
            assign
                SchemaObject.ObjectParent  = ""
                SchemaObject.ObjectName    = phDatasetHandle:name
                SchemaObject.ObjectAltName = phDatasetHandle:xml-node-name
                .
        end. /* not available */

        if available(SchemaObject) then
            assign
                SchemaObject.ObjectSchema = cObjectSchema
                SchemaObject.ObjectHandle = phDatasetHandle
                SchemaObject.ObjectType   = "dataset"
                .

        /* Register each temp-table of the dataset separately. */
        do iCount = 1 to phDatasetHandle:num-buffers:
            hTableHandle = phDatasetHandle:get-buffer-handle(iCount):table-handle.
            this-object:registerTempTable( input phDatasetHandle:name,
                                           input hTableHandle ).
            delete object hTableHandle no-error.
        end.
    end method. /* registerDataset */


    method public void registerTempTable ( input phTableHandle as handle ):
        this-object:registerTempTable ( input "",
                                        input phTableHandle ).
    end method. /* registerTempTable */


    method public void registerTempTable ( input pcParentObject as character,
                                           input phTableHandle  as handle ):
        define variable cObjectSchema as longchar no-undo.

        if not valid-handle(phTableHandle) or not phTableHandle:prepared then return.

        phTableHandle:write-xmlschema("longchar", cObjectSchema) no-error.
        if error-status:error then
            undo, throw new AppError(substitute("Error registering table '&1'", phTableHandle:name), -1).

        find first SchemaObject exclusive-lock
             where SchemaObject.ObjectParent eq pcParentObject
               and SchemaObject.ObjectName eq phTableHandle:name no-error.

        if not available(SchemaObject) then do:
            create SchemaObject.
            assign
                SchemaObject.ObjectParent  = pcParentObject
                SchemaObject.ObjectName    = phTableHandle:name
                SchemaObject.ObjectAltName = phTableHandle:xml-node-name
                .
        end.

        if available(SchemaObject) then
            assign
                SchemaObject.ObjectSchema = cObjectSchema
                SchemaObject.ObjectHandle = phTableHandle
                SchemaObject.ObjectType   = "temp-table"
                .
    end method. /* registerTempTable */

end class.
