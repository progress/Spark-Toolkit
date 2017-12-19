The default implementation of the StateManager is to produce a single JSON context
file within the PAS instance's temp directory, which contains all properties for a
given session. We have no direct control over the sessions themselves, but we can
be assured of a unique and consistent value with each request that can correspond
to a given user. With that information we can track the context (properties) as
needed. To provide a means of storing this data in a more centralized and manageable
location we must update the StateManager instance class and provide the necessary
database tables. These can be created within a new database or as part of an
existing database (your choice and needs may differ by application).

Within this project is a set of overloaded methods in a custom StateManager class.
These will provide the necessary code to update 2 basic tables to track our sessions
and the related context data for each session. To implement a custom implementation
of a manager class, open the startup.json file and adjust the object that defines the
interface for the appropriate manager instance (Spark.Core.Manager.IStateManager):

    {
        "Manager": "Spark.Core.Manager.IStateManager",
        "Implementation": "Spark.Core.Manager.StateManager"
    }

Above is the default implementation, and would be replaced by the full class path of
your custom class. A restart of the PAS instance is necessary to pick up the config
file and to create the new manager instance for all new sessions. Provided in this
project is a sample implementation of this behavior, as well as an altered version of
the session Shutdown procedure (shutdown.p) which will delete any old session records
along with orphaned context data.

For reference, the 2 tables used for this implementation are as follows, and require
a database with a LOB area, as the context data should be saved in a CLOB field.
The bare minimum schema for these tables is listed as follows:

    ADD TABLE "WebDataStore"
      AREA "Data Area"
      DESCRIPTION "Temporary storage area for large text objects (such as serialized temp-tables or datasets)"
      DUMP-NAME "webdatastore"
    
    ADD FIELD "WebSessionID" OF "WebDataStore" AS character 
      FORMAT "X(40)"
      INITIAL ""
      LABEL "Session ID"
      MAX-WIDTH 80
      ORDER 10
    
    ADD FIELD "ObjectName" OF "WebDataStore" AS character 
      FORMAT "x(20)"
      INITIAL ""
      LABEL "Object Name"
      MAX-WIDTH 40
      COLUMN-LABEL "Name"
      ORDER 20
    
    ADD FIELD "ObjectData" OF "WebDataStore" AS clob 
      FORMAT "x(8)"
      INITIAL ?
      LOB-AREA "LOB Area"
      LOB-BYTES 104857600
      LOB-SIZE 100M
      CLOB-CODEPAGE "UTF-8"
      CLOB-COLLATION "basic"
      CLOB-TYPE 2
      ORDER 30
    
    ADD FIELD "add_dt" OF "WebDataStore" AS date 
      DESCRIPTION "Date record was added"
      FORMAT "99/99/9999"
      INITIAL ?
      MAX-WIDTH 4
      ORDER 40
    
    ADD FIELD "add_time" OF "WebDataStore" AS integer 
      DESCRIPTION "Time this record was added"
      FORMAT "99999"
      INITIAL "0"
      MAX-WIDTH 4
      ORDER 50
    
    ADD FIELD "add_userid" OF "WebDataStore" AS character 
      DESCRIPTION "User ID of the person who added this record."
      FORMAT "X(30)"
      INITIAL ""
      MAX-WIDTH 60
      ORDER 60
    
    ADD FIELD "chg_dt" OF "WebDataStore" AS date 
      DESCRIPTION "Date record was changed"
      FORMAT "99/99/9999"
      INITIAL ?
      MAX-WIDTH 4
      ORDER 70
    
    ADD FIELD "chg_time" OF "WebDataStore" AS integer 
      DESCRIPTION "Time this record was added"
      FORMAT "99999"
      INITIAL "0"
      MAX-WIDTH 4
      ORDER 80
    
    ADD FIELD "chg_userid" OF "WebDataStore" AS character 
      DESCRIPTION "User ID of the person who last changed this record."
      FORMAT "X(30)"
      INITIAL ""
      MAX-WIDTH 60
      ORDER 90
    
    ADD INDEX "pkDataStore" ON "WebDataStore" 
      AREA "Index Area"
      UNIQUE
      PRIMARY
      INDEX-FIELD "WebSessionID" ASCENDING 
      INDEX-FIELD "ObjectName" ASCENDING
    
    ADD TABLE "WebSession"
      AREA "Data Area"
      DESCRIPTION "One record for each session over the web."
      DUMP-NAME "websession"
    
    ADD FIELD "WebSessionID" OF "WebSession" AS character 
      FORMAT "X(40)"
      INITIAL ""
      MAX-WIDTH 80
      ORDER 10
    
    ADD FIELD "StartDate" OF "WebSession" AS date 
      FORMAT "99/99/9999"
      INITIAL ?
      MAX-WIDTH 4
      ORDER 20
    
    ADD FIELD "LastDate" OF "WebSession" AS date 
      FORMAT "99/99/9999"
      INITIAL ?
      MAX-WIDTH 4
      ORDER 30
    
    ADD FIELD "StartTime" OF "WebSession" AS integer 
      FORMAT "->,>>>,>>9"
      INITIAL "0"
      MAX-WIDTH 4
      ORDER 40
    
    ADD FIELD "LastTime" OF "WebSession" AS integer 
      FORMAT "->,>>>,>>9"
      INITIAL "0"
      MAX-WIDTH 4
      ORDER 50

    ADD FIELD "SessionActive" OF "WebSession" AS logical 
      DESCRIPTION "Whether or not the session is still active and can receive hits."
      FORMAT "yes/no"
      INITIAL "yes"
      MAX-WIDTH 1
      ORDER 60

    ADD INDEX "pkWebSession" ON "WebSession" 
      AREA "Index Area"
      UNIQUE
      PRIMARY
      DESCRIPTION "Primary Unique Index of the WebSession Table"
      INDEX-FIELD "WebSessionID" ASCENDING 
    
    ADD INDEX "idxLastDateTime" ON "WebSession" 
      AREA "Index Area"
      INDEX-FIELD "LastDate" ASCENDING 
      INDEX-FIELD "LastTime" ASCENDING 
    
    ADD INDEX "idxSessionActive" ON "WebSession" 
      AREA "Index Area"
      INDEX-FIELD "SessionActive" ASCENDING 
    
    ADD INDEX "idxStartDateTime" ON "WebSession" 
      AREA "Index Area"
      INDEX-FIELD "StartDate" ASCENDING 
      INDEX-FIELD "StartTime" ASCENDING 
