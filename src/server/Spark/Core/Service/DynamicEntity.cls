 /*------------------------------------------------------------------------
    File        : DynamicEntity
    Purpose     :
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Tue Mar 17 09:31:42 EDT 2015
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.* from propath.
using Spark.Core.Manager.ICatalogManager from propath.
using Spark.Core.Manager.IMessageManager from propath.
using Spark.Core.Message.IRequest from propath.
using Spark.Core.Message.IResponse from propath.
using Spark.Core.Util.FormatTools from propath.

/* Default options for class. */
block-level on error undo, throw.

class Spark.Core.Service.DynamicEntity inherits Spark.Core.Service.SparkEntity implements Spark.Core.Service.IDynamicEntity use-widget-pool abstract:

    /**
     * Defined in OpenEdge.BusinessLogic.BusinessEntity as handle to DataSet in context:
     *   define protected property ProDataSet as handle no-undo get. set.
     */

    /* Name of dataset, derived from ProDataSet handle. */
    define public property entityName as character no-undo
        get:
            if valid-handle(ProDataSet) then
                return ProDataSet:name.
            return "".
        end get.
        protected set.

    /* Required property on instance class, denotes a known service path. */
    define public abstract property serviceURI as character no-undo
        get. protected set.

    /* Required property on instance class, denotes public name for resource. */
    define public abstract property resourceName as character no-undo
        get. protected set.

    /* Required property on instance class, denotes primary keys for entity. */
    define public abstract property primaryKeys as character no-undo
        get. protected set.

    /* Required property on instance class, denotes foreign keys for entity. */
    define public abstract property foreignKeys as character no-undo
        get. protected set.

    /* Required property on instance class, denotes JSDO mapping to utilize. */
    define public abstract property mappingType as character no-undo
        get. protected set.

    /* Required property on instance class, denotes capabilities for JSDO. */
    define public abstract property capabilities as character no-undo
        get. protected set.

    /* Required property on instance class, denotes operations allowed.
     * Comma-delimited list consisting of "CRUD" and/or "Submit" values.
     * An additional value of "ReadOnly" will disable the CUD methods.
     */
    define public abstract property operations as character no-undo
        get. protected set.

    /* Direct access to the request object. */
    define protected property oRequest as IRequest no-undo
        get:
            return cast(cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager):RequestMessage, IRequest).
        end get.
        private set.

    /* Direct access to the response object. */
    define protected property oResponse as IResponse no-undo
        get:
            return cast(cast(Ccs.Common.Application:StartupManager:getManager(get-class(IMessageManager)), IMessageManager):ResponseMessage, IResponse).
        end get.
        private set.

    /***** Protected *****/

    method protected JsonObject getFilter ( ):
        define variable oParser as ObjectModelParser no-undo.
        define variable oFilter as JsonObject        no-undo.
        define variable cFilter as longchar          no-undo.

        assign cFilter = oRequest:getParamAsLongChar(cast(Ccs.Common.Application:StartupManager:getManager(get-class(ICatalogManager)), ICatalogManager):ReadFilter, true).
        if cFilter ne ? and cFilter begins "~{" then do:
            assign oParser = new ObjectModelParser().
            assign cFilter = FormatTools:convertToUTF8(cFilter).
            assign oFilter = cast(oParser:Parse(cFilter), JsonObject).
            return oFilter.
        end.

        return ?.

        finally:
            delete object oParser no-error.
            assign cFilter = "".
        end finally.
    end method. /* getFilter */

    /******* Public *******/

end class.
