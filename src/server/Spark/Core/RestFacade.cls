@openapi.openedge.export FILE(type="REST", executionMode="singleton", useReturnValue="false", writeDataSetBeforeImage="false").
/*------------------------------------------------------------------------
    File        : Spark.Core.RestFacade
    Purpose     : Provide a simple facade for CRUD operations.
    Description : This exists behind static mappings for REST transport.
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Fri Dec 12 10:14:53 EST 2014
    Notes       : Special version of RestFacade for project instances.
                  Copy into your project's AppServer/<project> folder,
                  and change the class path below to match. You can then
                  map the following resource endpoints:
                     /catalog
                        GET: getCatalogAll
                     /catalog/{pcResourceName}
                        GET: getCatalog
                     /{pcResourceName}
                        GET: doRead
                        PUT: doUpdate
                        POST: doCreate
                        DELETE: doDestroy
                     /{pcResourceName}/{pcMethodName}
                        GET: doGet
                        PUT: doPut
                        POST: doPost
                        DELETE: doDelete
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.

block-level on error undo, throw.

class Spark.Core.RestFacade inherits Spark.Core.Interface.ServiceInterface implements Spark.Core.Interface.IRestFacade use-widget-pool final:

    /** Catalog Operations **/


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    method public void getCatalog ( input  pcServiceURI   as character,
                                    input  pcResourceName as character,
                                    output pfElapsedTime  as decimal,
                                    output piResponseCode as integer,
                                    output pcJsonResponse as longchar ):
        define variable cJsonHeaders as longchar no-undo.
        runService( input  pcResourceName,
                    input  "getCatalog",
                    input  "GET",
                    input  pcServiceURI,
                    input  "",
                    output pfElapsedTime,
                    output piResponseCode,
                    output cJsonHeaders,
                    output pcJsonResponse ).
    end method. /* getCatalog */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    method public void getCatalogAll ( output pfElapsedTime  as decimal,
                                       output piResponseCode as integer,
                                       output pcJsonResponse as longchar ):
        define variable cJsonHeaders as longchar no-undo.
        runService( input  "all", /* Obtain all resources. */
                    input  "getCatalog",
                    input  "GET",
                    input  "", /* Obtain all services. */
                    input  "",
                    output pfElapsedTime,
                    output piResponseCode,
                    output cJsonHeaders,
                    output pcJsonResponse ).
    end method. /* getCatalogAll */


    /** CRUD Operations **/


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    method public void doCreate ( input  pcResourceName as character,
                                  input  pcMethodName   as character,
                                  input  pcServiceObj   as character,
                                  input  pcJsonRequest  as longchar,
                                  output plResult       as logical,
                                  output pfElapsedTime  as decimal,
                                  output piResponseCode as integer,
                                  output pcJsonResponse as longchar ):
        define variable cJsonHeaders as longchar no-undo.
        assign plResult = runService( input  pcResourceName,
                                      input  if (pcMethodName gt "") eq true then pcMethodName else "create",
                                      input  "post",
                                      input  pcServiceObj,
                                      input  pcJsonRequest,
                                      output pfElapsedTime,
                                      output piResponseCode,
                                      output cJsonHeaders,
                                      output pcJsonResponse ).
    end method. /* doCreate */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    method public void doRead ( input  pcResourceName as character,
                                input  pcMethodName   as character,
                                input  pcServiceObj   as character,
                                input  pcJsonRequest  as longchar,
                                output plResult       as logical,
                                output pfElapsedTime  as decimal,
                                output piResponseCode as integer,
                                output pcJsonResponse as longchar ):
        define variable cJsonHeaders as longchar no-undo.
        assign plResult = runService( input  pcResourceName,
                                      input  if (pcMethodName gt "") eq true then pcMethodName else "read",
                                      input  "get",
                                      input  pcServiceObj,
                                      input  pcJsonRequest,
                                      output pfElapsedTime,
                                      output piResponseCode,
                                      output cJsonHeaders,
                                      output pcJsonResponse ).
    end method. /* doRead */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    method public void doUpdate ( input  pcResourceName as character,
                                  input  pcMethodName   as character,
                                  input  pcServiceObj   as character,
                                  input  pcJsonRequest  as longchar,
                                  output plResult       as logical,
                                  output pfElapsedTime  as decimal,
                                  output piResponseCode as integer,
                                  output pcJsonResponse as longchar ):
        define variable cJsonHeaders as longchar no-undo.
        assign plResult = runService( input  pcResourceName,
                                      input  if (pcMethodName gt "") eq true then pcMethodName else "update",
                                      input  "put",
                                      input  pcServiceObj,
                                      input  pcJsonRequest,
                                      output pfElapsedTime,
                                      output piResponseCode,
                                      output cJsonHeaders,
                                      output pcJsonResponse ).
    end method. /* doUpdate */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    method public void doDestroy ( input  pcResourceName as character,
                                   input  pcMethodName   as character,
                                   input  pcServiceObj   as character,
                                   input  pcJsonRequest  as longchar,
                                   output plResult       as logical,
                                   output pfElapsedTime  as decimal,
                                   output piResponseCode as integer,
                                   output pcJsonResponse as longchar ):
        define variable cJsonHeaders as longchar no-undo.
        assign plResult = runService( input  pcResourceName,
                                      input  if (pcMethodName gt "") eq true then pcMethodName else "delete",
                                      input  "delete",
                                      input  pcServiceObj,
                                      input  pcJsonRequest,
                                      output pfElapsedTime,
                                      output piResponseCode,
                                      output cJsonHeaders,
                                      output pcJsonResponse ).
    end method. /* doDelete */


    /** Verb Operations **/


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    method public void doGet ( input  pcResourceName as character,
                               input  pcMethodName   as character,
                               input  pcServiceObj   as character,
                               input  pcJsonRequest  as longchar,
                               output plResult       as logical,
                               output pfElapsedTime  as decimal,
                               output piResponseCode as integer,
                               output pcJsonResponse as longchar ):
        define variable cJsonHeaders as longchar no-undo.
        assign plResult = runService( input  pcResourceName,
                                      input  pcMethodName,
                                      input  "get",
                                      input  pcServiceObj,
                                      input  pcJsonRequest,
                                      output pfElapsedTime,
                                      output piResponseCode,
                                      output cJsonHeaders,
                                      output pcJsonResponse ).
    end method. /* doGet */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    method public void doPut ( input  pcResourceName as character,
                               input  pcMethodName   as character,
                               input  pcServiceObj   as character,
                               input  pcJsonRequest  as longchar,
                               output plResult       as logical,
                               output pfElapsedTime  as decimal,
                               output piResponseCode as integer,
                               output pcJsonResponse as longchar ):
        define variable cJsonHeaders as longchar no-undo.
        assign plResult = runService( input  pcResourceName,
                                      input  pcMethodName,
                                      input  "put",
                                      input  pcServiceObj,
                                      input  pcJsonRequest,
                                      output pfElapsedTime,
                                      output piResponseCode,
                                      output cJsonHeaders,
                                      output pcJsonResponse ).
    end method. /* doPut */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    method public void doPost ( input  pcResourceName as character,
                                input  pcMethodName   as character,
                                input  pcServiceObj   as character,
                                input  pcJsonRequest  as longchar,
                                output plResult       as logical,
                                output pfElapsedTime  as decimal,
                                output piResponseCode as integer,
                                output pcJsonResponse as longchar ):
        define variable cJsonHeaders as longchar no-undo.
        assign plResult = runService( input  pcResourceName,
                                      input  pcMethodName,
                                      input  "post",
                                      input  pcServiceObj,
                                      input  pcJsonRequest,
                                      output pfElapsedTime,
                                      output piResponseCode,
                                      output cJsonHeaders,
                                      output pcJsonResponse ).
    end method. /* doPost */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    method public void doDelete ( input  pcResourceName as character,
                                  input  pcMethodName   as character,
                                  input  pcServiceObj   as character,
                                  input  pcJsonRequest  as longchar,
                                  output plResult       as logical,
                                  output pfElapsedTime  as decimal,
                                  output piResponseCode as integer,
                                  output pcJsonResponse as longchar ):
        define variable cJsonHeaders as longchar no-undo.
        assign plResult = runService( input  pcResourceName,
                                      input  pcMethodName,
                                      input  "delete",
                                      input  pcServiceObj,
                                      input  pcJsonRequest,
                                      output pfElapsedTime,
                                      output piResponseCode,
                                      output cJsonHeaders,
                                      output pcJsonResponse ).
    end method. /* doDelete */


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    method public void logoutUser ( output pfElapsedTime  as decimal,
                                    output piResponseCode as integer,
                                    output plResult       as logical,
                                    output pcMessage      as character ):

        assign pfElapsedTime = mtime.
        assign
            piResponseCode = 200
            plResult = userLogout( output pcMessage )
            pfElapsedTime  = (mtime - pfElapsedTime)
            .
    end method.

end class.