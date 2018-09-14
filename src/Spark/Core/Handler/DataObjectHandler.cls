/*------------------------------------------------------------------------
    File        : DataObjectHandler
    Purpose     : Example of a WebHandler that can execute requests in a
                  dynamic manner. Can return just a PDO catalog or execute
                  a standard Progress Data Object within the framework.
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Thu Feb 11 10:24:51 EST 2016
    Notes       : Should currently support GET, POST, PUT, DELETE methods.
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using Spark.Core.Interface.IServiceFacade from propath.
using Spark.Core.Manager.IClientContext from propath.
using Spark.Core.Manager.ICatalogManager from propath.
using Spark.Core.Manager.IMessageManager from propath.
using Spark.Core.Web.SparkRequest from propath.
using Spark.Core.Web.SparkResponse from propath.

block-level on error undo, throw.

/**
 * This handler will utilize the runService method in the facade of your choosing:
 *  Spark.Core.DirectFacade - Code to be invoked is on the local filesystem.
 *  Spark.Core.RemoteFacade - Utilizes an APSV connection to run ApsvFacade.
 *
 * When utilizing the DirectFacade, the catalog.json config file must be setup with
 * information about your available services and where to find the code to register
 * with the CatalogManager. And when using RemoteFacade you must update the config
 * connection.json with a valid AppServer entry to connect to--this must be setup
 * with the Spark framework making the procedure Spark/Core/ApsvFacade.p available.
 */

class Spark.Core.Handler.DataObjectHandler inherits Spark.Core.Handler.SparkHandler final use-widget-pool:

    define protected property ServicePrefix as character no-undo
        get():
            if (ServicePrefix gt "") ne true then do:
                if valid-object(Ccs.Common.Application:StartupManager) and
                   valid-object(Ccs.Common.Application:StartupManager:getManager(get-class(ICatalogManager))) then
                    assign ServicePrefix = cast(Ccs.Common.Application:StartupManager:getManager(get-class(ICatalogManager)), ICatalogManager):ServicePrefix.
                else
                    assign ServicePrefix = "pdo".
            end.
            return ServicePrefix.
        end get.
        private set.

    define override protected property oServiceFacade as IServiceFacade no-undo
        get():
            if not valid-object(oServiceFacade) then do:
                if getHandlerFacadeType(getClassName()) eq "Remote" then do:
                    define variable cServerName as character no-undo.
                    define variable cRemoteProc as character no-undo.

                    assign cServerName = getHandlerRemoteServer(getClassName()).
                    assign cRemoteProc = getHandlerRemoteProc(cServerName).

                    oServiceFacade = new Spark.Core.RemoteFacade(cServerName, cRemoteProc).
                end.
                else
                    oServiceFacade = new Spark.Core.DirectFacade().
            end.
            return oServiceFacade.
        end get.
        set.

    constructor public DataObjectHandler ( ):
        message "NOTICE: The Spark.Core.Handler.DataObjectHandler is slated for deprecation in the near future. "
              + "Please use the product-supplied OpenEdge.Web.DataObject.DataObjectHandler instead.".
    end constructor.


    /** Protected Methods **/


    method protected override integer runServiceAndRespond ( ):
        define variable oSparkRequest  as SparkRequest  no-undo.
        define variable oSparkResponse as SparkResponse no-undo.

        /* Create a custom WebRequest object, using a particular path prefix. */
        assign oSparkRequest = new SparkRequest(this-object:ServicePrefix).
        assign oSparkResponse = new SparkResponse().

        /* Run the requested service via the appropriate facade (currently: Direct or Remote). */
        oServiceFacade:runService( input oSparkRequest:SparkResourceName, /* Business Entity */
                                   input oSparkRequest:SparkMethodName, /* Derived Method */
                                   input oSparkRequest:Method, /* HTTP Verb */
                                   input oSparkRequest:SparkServiceURI, /* Service Path */
                                   input oSparkRequest:SparkBody, /* Extract payload. */
                                   input oSparkRequest, /* Pass custom request object. */
                                   input oSparkResponse, /* Pass target response object. */
                                   input oSparkRequest:SparkApiVersion, /* Optional Version */
                                   input oSparkRequest:SparkStopAfter /* Defined Time Limit */ ).

        /* Use response object to write output to webstream. */
        writeResponse(oSparkResponse).

        return 0.

        finally:
            delete object oSparkRequest  no-error.
            delete object oSparkResponse no-error.
        end finally.
    end method. /* runServiceAndRespond */

end class.