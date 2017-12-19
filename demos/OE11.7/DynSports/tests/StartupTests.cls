/*------------------------------------------------------------------------
    File        : StartupTests
    Purpose     :
    Syntax      :
    Description :
    Author(s)   : dugrau@progress.com
    Created     : Thu May 25 14:10:52 EDT 2017
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.

block-level on error undo, throw.

class tests.StartupTests inherits tests.PMFOUnit:

	/*------------------------------------------------------------------------------
	 Purpose: Start up the PMFO stack similar to a session of the MSAS agent.
	 Notes:
	------------------------------------------------------------------------------*/
	@Before.
	method public void before ( ):
        this-object:StartPMFO().
	end method.

    /*------------------------------------------------------------------------------
     Purpose: Shut down the PMFO stack similar to a session of the MSAS agent.
     Notes:
    ------------------------------------------------------------------------------*/
    @After.
    method public void after ( ):
        this-object:StopPMFO().
    end method.


    /*------------------------------------------------------------------------------
        Purpose:
        Notes:
    ------------------------------------------------------------------------------*/
    @Setup.
    method public void setUp ( ):
    end method.

    /*------------------------------------------------------------------------------
        Purpose:
        Notes:
    ------------------------------------------------------------------------------*/
    @TearDown.
    method public void tearDown ( ):
    end method.

    /*------------------------------------------------------------------------------
        Purpose: Confirm the number of expected databases are connected
        Notes:
    ------------------------------------------------------------------------------*/
    @Test.
    method public void testDatabases ( ):
        OpenEdge.Core.Assert:Equals(this-object:NumDatabases, num-dbs).
    end method.

    /*------------------------------------------------------------------------------
        Purpose: Confirm the Application is present and valid
        Notes:
    ------------------------------------------------------------------------------*/
    @Test.
    method public void testApplication ( ):
        define variable oApp as Progress.Lang.Class no-undo.
        assign oApp = Progress.Lang.Class:GetClass("Ccs.Common.Application") no-error.       
        OpenEdge.Core.Assert:IsTrue(valid-object(oApp)).
    end method.

    /*------------------------------------------------------------------------------
        Purpose: Confirm the StartupManager is present and valid.
        Notes:
    ------------------------------------------------------------------------------*/
    @Test.
    method public void testStartupManager ( ):
        OpenEdge.Core.Assert:IsTrue(valid-object(Ccs.Common.Application:StartupManager)).
    end method.

    /*------------------------------------------------------------------------------
        Purpose: Confirm the ServiceManager is present and valid.
        Notes:
    ------------------------------------------------------------------------------*/
    @Test.
    method public void testServiceManager ( ):
        OpenEdge.Core.Assert:IsTrue(valid-object(Ccs.Common.Application:ServiceManager)).
    end method.

    /*------------------------------------------------------------------------------
        Purpose: Confirm the SessionManager is present and valid.
        Notes:
    ------------------------------------------------------------------------------*/
    @Test.
    method public void testSessionManager ( ):
        OpenEdge.Core.Assert:IsTrue(valid-object(Ccs.Common.Application:SessionManager)).
    end method.

    /*------------------------------------------------------------------------------
        Purpose: Confirm the IManager interface is present and valid.
        Notes:
    ------------------------------------------------------------------------------*/
    @Test.
    method public void testManager ( ):
        OpenEdge.Core.Assert:IsTrue(this-object:HasManagerInterface()).
    end method.

    /*------------------------------------------------------------------------------
        Purpose: Confirm the CatalogManager is present and valid.
        Notes:
    ------------------------------------------------------------------------------*/
    @Test.
    method public void testCatalogManager ( ):
        define variable oManager as Progress.Lang.Object no-undo.
        assign oManager = this-object:GetManager("Spark.Core.Manager.ICatalogManager").
        OpenEdge.Core.Assert:IsTrue(valid-object(oManager)).
    end method.

    /*------------------------------------------------------------------------------
        Purpose: Confirm the ConnectionManager is present and valid.
        Notes:
    ------------------------------------------------------------------------------*/
    @Test.
    method public void testConnectionManager ( ):
        define variable oManager as Progress.Lang.Object no-undo.
        assign oManager = this-object:GetManager("Spark.Core.Manager.IConnectionManager").
        OpenEdge.Core.Assert:IsTrue(valid-object(oManager)).
    end method.

    /*------------------------------------------------------------------------------
        Purpose: Confirm the LoggingManager is present and valid.
        Notes:
    ------------------------------------------------------------------------------*/
    @Test.
    method public void testLoggingManager ( ):
        define variable oManager as Progress.Lang.Object no-undo.
        assign oManager = this-object:GetManager("Spark.Core.Manager.ILoggingManager").
        OpenEdge.Core.Assert:IsTrue(valid-object(oManager)).
    end method.

    /*------------------------------------------------------------------------------
        Purpose: Confirm the MessageManager is present and valid.
        Notes:
    ------------------------------------------------------------------------------*/
    @Test.
    method public void testMessageManager ( ):
        define variable oManager as Progress.Lang.Object no-undo.
        assign oManager = this-object:GetManager("Spark.Core.Manager.IMessageManager").
        OpenEdge.Core.Assert:IsTrue(valid-object(oManager)).
    end method.

    /*------------------------------------------------------------------------------
        Purpose: Confirm the RouteManager is present and valid.
        Notes:
    ------------------------------------------------------------------------------*/
    @Test.
    method public void testRouteManager ( ):
        define variable oManager as Progress.Lang.Object no-undo.
        assign oManager = this-object:GetManager("Spark.Core.Manager.IRouteManager").
        OpenEdge.Core.Assert:IsTrue(valid-object(oManager)).
    end method.

    /*------------------------------------------------------------------------------
        Purpose: Confirm the SchemaManager is present and valid.
        Notes:
    ------------------------------------------------------------------------------*/
    @Test.
    method public void testSchemaManager ( ):
        define variable oManager as Progress.Lang.Object no-undo.
        assign oManager = this-object:GetManager("Spark.Core.Manager.ISchemaManager").
        OpenEdge.Core.Assert:IsTrue(valid-object(oManager)).
    end method.

    /*------------------------------------------------------------------------------
        Purpose: Confirm the StateManager is present and valid.
        Notes:
    ------------------------------------------------------------------------------*/
    @Test.
    method public void testStateManager ( ):
        define variable oManager as Progress.Lang.Object no-undo.
        assign oManager = this-object:GetManager("Spark.Core.Manager.IStateManager").
        OpenEdge.Core.Assert:IsTrue(valid-object(oManager)).
    end method.

    /*------------------------------------------------------------------------------
        Purpose: Confirm the StatsManager is present and valid.
        Notes:
    ------------------------------------------------------------------------------*/
    @Test.
    method public void testStatsManager ( ):
        define variable oManager as Progress.Lang.Object no-undo.
        assign oManager = this-object:GetManager("Spark.Core.Manager.IStatsManager").
        OpenEdge.Core.Assert:IsTrue(valid-object(oManager)).
    end method.

    /*------------------------------------------------------------------------------
        Purpose: Confirm the TranslationManager is present and valid.
        Notes:
    ------------------------------------------------------------------------------*/
    @Test.
    method public void testTranslationManager ( ):
        define variable oManager as Progress.Lang.Object no-undo.
        assign oManager = this-object:GetManager("Spark.Core.Manager.ITranslationManager").
        OpenEdge.Core.Assert:IsTrue(valid-object(oManager)).
    end method.

end class.