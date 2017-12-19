/*------------------------------------------------------------------------
    File        : ParameterTests
    Purpose     :
    Syntax      :
    Description :
    Author(s)   : dugrau@progress.com
    Created     : Thu May 30 19:10:52 EDT 2017
    Notes       :
  ----------------------------------------------------------------------*/

&global-define test_username dev@spark
&global-define allowed_roles PSCUser,EndUser
&global-define domain_passkey oech1::23222e35397562

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.

block-level on error undo, throw.

class tests.ParameterTests inherits tests.PMFOUnit:

    define private variable hCPO as handle no-undo.

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

        finally:
            delete object hCPO no-error.
        end finally.
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
        Purpose: Confirm the StartupManager is present and valid.
        Notes:
    ------------------------------------------------------------------------------*/
    @Test.
    method public void testStartupManager ( ):
        OpenEdge.Core.Assert:IsTrue(valid-object(Ccs.Common.Application:StartupManager)).
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
        Purpose: Confirm a DirectFacade is present and usable.
        Notes:
    ------------------------------------------------------------------------------*/
    @Test.
    method public void testDirectFacade ( ):
        define variable oFacade as Spark.Core.DirectFacade no-undo.
        assign oFacade = new Spark.Core.DirectFacade().
        OpenEdge.Core.Assert:IsTrue(valid-object(oFacade)).
    end method.

    /*------------------------------------------------------------------------------
        Purpose: Confirm a login can be performed against the service facade.
        Notes:
    ------------------------------------------------------------------------------*/
    @Test.
    method public void testCreateCPO ( ):
        define variable oFacade  as Spark.Core.DirectFacade no-undo.
        define variable cMessage as character               no-undo.
        define variable lResult  as logical                 no-undo.
        define variable rCP      as raw                     no-undo.

        create client-principal hCPO.
        hCPO:initialize("{&test_username}").
        hCPO:roles = "{&allowed_roles}".
        hCPO:set-property("ATTR_ENABLED", "true").
        hCPO:set-property("ATTR_LOCKED", "false").
        hCPO:set-property("ATTR_EXPIRED", "false").
        hCPO:seal("{&domain_passkey}").

        OpenEdge.Core.Assert:IsTrue(hCPO:validate-seal("{&domain_passkey}")).
    end method.

    /*------------------------------------------------------------------------------
        Purpose: Confirm a request can be performed against the service facade.
        Notes:
    ------------------------------------------------------------------------------*/
    @Test.
    method public void testFacadeService ( ):
        define variable oFacade        as Spark.Core.DirectFacade no-undo.
        define variable oRequest       as JsonObject              no-undo.
        define variable oResponse      as JsonObject              no-undo.
        define variable oParser        as ObjectModelParser       no-undo.
        define variable lResult        as logical                 no-undo.
        define variable fElapsedTime   as decimal                 no-undo.
        define variable iResponseCode  as integer                 no-undo.
        define variable lcJsonRequest  as longchar                no-undo.
        define variable lcJsonHeaders  as longchar                no-undo.
        define variable lcJsonResponse as longchar                no-undo.

        assign oRequest = new JsonObject().
        oRequest:Add("inString", "Hello World").
        oRequest:Add("inDecimal", 3.1415).
        oRequest:Add("inInteger", 12345).
        oRequest:Add("inDate", today).
        oRequest:Add("inDTime", datetime(today)).
        oRequest:Add("inDTimeTZ", datetime-tz(now)).
        lcJsonRequest = oRequest:GetJsonText().

        /* NOTE: Must be run after "testCreateCPO" so that handle "hCPO" is properly set. */
        assign oFacade = new Spark.Core.DirectFacade().
        assign lResult = oFacade:runService ( input  hCPO,
                                              input  "params",
                                              input  "primitives",
                                              input  "PUT",
                                              input  "/web/pdo/tests",
                                              input  lcJsonRequest,
                                              output fElapsedTime,
                                              output iResponseCode,
                                              output lcJsonHeaders,
                                              output lcJsonResponse ).

        /* Initial tests, checking for successful response. */
        OpenEdge.Core.Assert:IsTrue(lResult).
        OpenEdge.Core.Assert:Equals(200, iResponseCode).

        /* Parse response into a valid JsonObject. */
        if (lcJsonResponse gt "") eq true and lcJsonResponse begins "~{" then do:
            assign oParser = new ObjectModelParser().
            assign oResponse = cast(oParser:Parse(lcJsonResponse), JsonObject).
            delete object oParser no-error.
        end.
        else
            OpenEdge.Core.Assert:RaiseError("Response was not a valid JSON string.").

        /* Test returned parameters against original values (all should match). */
        if valid-object(oResponse) then do:
            OpenEdge.Core.Assert:Equals(oRequest:GetCharacter("inString"), oResponse:GetCharacter("outString")).
            OpenEdge.Core.Assert:Equals(oRequest:GetDecimal("inDecimal"), oResponse:GetDecimal("outDecimal")).
            OpenEdge.Core.Assert:Equals(oRequest:GetInteger("inInteger"), oResponse:GetInteger("outInteger")).
            OpenEdge.Core.Assert:Equals(string(oRequest:GetDate("inDate")), string(oResponse:GetDate("outDate"))).
            OpenEdge.Core.Assert:Equals(string(oRequest:GetDateTime("inDTime")), string(oResponse:GetDateTime("outDTime"))).
            OpenEdge.Core.Assert:Equals(string(oRequest:GetDateTimeTZ("inDTimeTZ")), string(oResponse:GetDateTimeTZ("outDTimeTZ"))).
        end.
    end method.

end class.