/* *************************************************************************************************************************
Copyright (c) 2018 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
************************************************************************************************************************** */
/*------------------------------------------------------------------------
    File        : OpenAPI30ServiceWriter
    Purpose     : Writes a DataObjectService to a OpenApi (Swagger) 3.0 doc
    Syntax      :
    Description :
    Author(s)   : pjudge
    Created     : 2018-09-20
    Notes       : - https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.1.md
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Core.Assert.
using OpenEdge.Core.Collections.IIterator.
using OpenEdge.Core.SemanticVersion.
using OpenEdge.Core.String.
using OpenEdge.Net.HTTP.HttpHeader.
using OpenEdge.Net.HTTP.HttpHeaderCollection.
using OpenEdge.Net.HTTP.MethodEnum.
using OpenEdge.Net.URI.
using OpenEdge.Web.DataObject.DataObjectService.
using OpenEdge.Web.DataObject.ElementTypeEnum.
using OpenEdge.Web.DataObject.MappedOperation.
using OpenEdge.Web.DataObject.MessageElement.
using OpenEdge.Web.DataObject.OperationParameter.
using OpenEdge.Web.DataObject.TargetTypeEnum.
using OpenEdge.Web.DataObject.Writer.DataObjectServiceWriter.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Json.ObjectModel.JsonDataType.
using Progress.Json.ObjectModel.JsonObject.
using OpenEdge.Net.MimeTypeHelper.
using OpenEdge.Core.Json.PropertyHelper.

class OpenEdge.Web.DataObject.Writer.OpenAPI30ServiceWriter inherits DataObjectServiceWriter:
    /* The version of the OpenAPI spec that is produced */
    define static public property OPEN_API_VERSION as SemanticVersion no-undo
        get.
        private set.

    /* STatic constructor */
    constructor static OpenAPI30ServiceWriter():
        assign OPEN_API_VERSION = new SemanticVersion(3,0,1).
    end constructor.

    /* Default constructor */
    constructor public OpenAPI30ServiceWriter():
        super (get-class(JsonObject)).
    end constructor.

    method override public void Open():
        // If nothing's passed in, create an instance of the Argument Type
        if not valid-object(this-object:Value) then
            assign this-object:Value = WriteServiceRoot().

        super:Open().
    end method.

    /* A set of default server objects

      @return JsonArray A set of default server objects */
    method protected JsonArray WriteDefaultServers():
        define variable servers as JsonArray no-undo.
        define variable arrayData as JsonArray no-undo.
        define variable defaultServer as JsonObject no-undo.
        define variable varData as JsonObject no-undo.
        define variable childData as JsonObject no-undo.

        assign servers       = new JsonArray()
               defaultServer = new JsonObject()
               childData     = new JsonObject()
               .
        // abs path
        servers:Add(defaultServer).

        defaultServer:Add('url':u, '~{scheme}://~{host}:~{port}~{ctx}/web~{basePath}':u).
        defaultServer:Add('description':u, 'Default server configuration':u).
        defaultServer:Add('variables':u, childData).

        assign varData   = new JsonObject()
               arrayData = new JsonArray()
               .
        childData:Add('scheme':u, varData).
            varData:Add('enum':u, arrayData).
                arrayData:Add('http':u).
                arrayData:Add('https':u).
            varData:Add('default':u, 'http':u).

        assign varData   = new JsonObject()
               arrayData = new JsonArray()
               .
        childData:Add('host':u, varData).
            varData:Add('default':u, 'localhost':u).

        assign varData   = new JsonObject()
               arrayData = new JsonArray()
               .
        childData:Add('port':u, varData).
            varData:Add('default':u, '8810':u).

        assign varData   = new JsonObject()
               arrayData = new JsonArray()
               .
        childData:Add('ctx':u, varData).
            varData:Add('description':u, 'The webapp/context for this service. Empty/blank indicates ROOT':u).
            varData:Add('default':u, '':u).

        assign varData = new JsonObject().
        childData:Add('basePath':u, varData).
            varData:Add('default':u, '/pdo':u).

        // relative path. will work relative to the OpenApi doc location
        assign defaultServer = new JsonObject()
               childData     = new JsonObject()
               .
        servers:Add(defaultServer).

        defaultServer:Add('url':u, '~{ctx}/web~{basePath}':u).
        defaultServer:Add('description':u, 'Default relative-path server configuration':u).
        defaultServer:Add('variables':u, childData).

        assign varData   = new JsonObject()
               arrayData = new JsonArray()
               .
        childData:Add('ctx':u, varData).
            varData:Add('description':u, 'The webapp/context for this service. Empty/blank indicates ROOT':u).
            varData:Add('default':u, '':u).

        assign varData = new JsonObject().
        childData:Add('basePath':u, varData).
            varData:Add('default':u, '/pdo':u).

        return servers.
    end method.

    /* Writes the "info" element's default values

       @return JsonObject The INFO object values */
    method protected JsonObject WriteInfo():
        define variable infoData as JsonObject no-undo.
        define variable childData as JsonObject no-undo.

        assign infoData = new JsonObject().
        //string  Required. The title of the application.
        infoData:Add('title':u, 'OpenAPI documentation for DataObjectHandler-based services':u).
        //string  A short description of the application. GFM syntax can be used for rich text representation.
        infoData:Add('description':u, '':u).
        //string  The Terms of Service for the API.
        infoData:Add('termsOfService':u, '':u).

        // The version of the OpenAPI document (which is distinct from the OpenAPI Specification
        // version or the API implementation version).
        infoData:Add('version':u, '1.0.0':u).

        return infoData.
    end method.

    /* Writes the top-level / root of the doc and default values

       @return JsonObject The root object values */
    method protected JsonObject WriteServiceRoot():
        define variable svcJson as JsonObject no-undo.

        assign svcJson = new JsonObject().

        svcJson:Add('openapi':u,    string(OPEN_API_VERSION)).      //REQUIRED. This string MUST be the semantic version number of the OpenAPI Specification version that the OpenAPI document uses. The openapi field SHOULD be used by tooling specifications and clients to interpret the OpenAPI document. This is not related to the API info.version string.
        svcJson:Add('info':u,       WriteInfo()).
        svcJson:Add('servers':u,    WriteDefaultServers()).         //An array of Server Objects, which provide connectivity information to a target server. If the servers property is not provided, or is an empty array, the default value would be a Server Object with a url value of /.
        svcJson:Add('paths':u,      new JsonObject()).              //REQUIRED. The available paths and operations for the API.

        //An element to hold various schemas for the specification.
        PropertyHelper:GetObjectValue(svcJson, 'components':U)
            :Add('schemas':u, WriteDefaultSchemas()).

        svcJson:Add('security':u,      new JsonArray()).   //A declaration of which security mechanisms can be used across the API. The list of values includes alternative security requirement objects that can be used. Only one of the security requirement objects need to be satisfied to authorize a request. Individual operations can override this definition.
        svcJson:Add('tags':u,          new JsonArray()).   //A list of tags used by the specification with additional metadata. The order of the tags can be used to reflect on their order by the parsing tools. Not all tags that are used by the Operation Object must be declared. The tags that are not declared MAY be organized randomly or based on the tools' logic. Each tag name in the list MUST be unique.

        return svcJson.
    end method.

    /* Writes any default (shared) schemas

       @return JsonObject The schema object values */
    method protected JsonObject WriteDefaultSchemas():
        define variable schemas as JsonObject no-undo.

        assign schemas = new JsonObject().

        //schemas:Add('dataServiceCatalog':u, schemaData).
            // Requires a cdo.json to be deployed 'next to' this openapi.json document
            //schemaData:Add('$ref':u, 'cdo.json#/components/schemas/dataServiceCatalog').

        return schemas.
    end method.

    /* Writes the JSON for a particular path (operation)

       @param DataObjectService The parent service
       @param character The relative URI for the operaton
       @param MethodEnum The HTTP method of this operation
       @return JsonObject The schema object values */
    method protected JsonObject GetPathJson(input pService as DataObjectService,
                                            input pUri as character,
                                            input pMethod as MethodEnum):
        define variable pathJson as JsonObject no-undo.
        define variable uriJson as JsonObject no-undo.
        define variable path as character no-undo.
        define variable svcName as character no-undo.
        define variable operationJson as JsonObject no-undo.

        assign svcName = pService:Name.
        if svcName eq DataObjectService:ROOT_SERVICE_NAME then
            assign svcName = DataObjectService:ROOT_SERVICE_URI.

        assign pathJson = PropertyHelper:GetObjectValue(cast(this-object:Value, JsonObject), 'paths':u)
               path     = left-trim(svcName + '/':u + left-trim(pURI, '/':u), '/':u)
               path     = '/':u + path
               uriJson  = PropertyHelper:GetObjectValue(pathJson, path)
               .
        if uriJson:Has(lc(string(pMethod))) then
            assign operationJson = uriJson:GetJsonObject(lc(string(pMethod))).
        else
        do:
            assign operationJson = new JsonObject().
            uriJson:Add(lc(string(pMethod)), operationJson).

            operationJson:Add('tags':u,          new JsonArray()).
            operationJson:Add('summary':u,       '':u).
            operationJson:Add('description':u,   '':u).
            operationJson:Add('operationId':u,   '':u).
            operationJson:Add('responses':u,     new JsonObject()).
            operationJson:Add('security':u,      new JsonArray()).
        end.

        return operationJson.
    end method.

    /* Writes the headers for an operation

       @param HttpHeaderCollection The headers to write
       @param JsonObject      The schema object values */
    method protected void WriteHeaders(input pData as HttpHeaderCollection,
                                       input pHeaderRoot as JsonObject):
        define variable hdrData as JsonObject no-undo.
        define variable headers as HttpHeader extent no-undo.
        define variable loop as integer no-undo.
        define variable cnt as integer no-undo.

        if pData:Size eq 0 then
            return.

        assign cnt     = pData:GetAll(headers)
               hdrData = new JsonObject()
               .
        hdrData:Add('description':u, '':u).
        hdrData:Add('type':u,        'string':u).

        do loop = 1 to cnt:
            pHeaderRoot:Add(headers[loop]:Name, hdrData).
        end.
    end method.

    /* Writes content/schemas for FILE operations

       @param MappedOperation The operations
       @param JsonObject The content root for the response */
    method protected void WriteFileSchema(input pOperation as MappedOperation,
                                          input pResponseRoot as JsonObject):
        define variable schemaRoot as JsonObject no-undo.
        define variable mimeType as character extent 2 no-undo.

        assign mimeType   = MimeTypeHelper:SplitType(pOperation:ContentType)
               schemaRoot = PropertyHelper:GetObjectValue(pResponseRoot, 'schema':u)
               .
        case mimeType[2]:
            when 'json':u then
            do:
                if pOperation:Name eq 'dataservice.catalog':u then
                    schemaRoot:Add('$ref':u, GetCatalogSchema(?)).
                else
                    schemaRoot:Add('type':u, 'object':u).
            end.

            // binary stuff
            when 'pdf':u or
            when 'zip':u or
            when 'gzip':u or
            when 'octet-stream':u then
            do:
                schemaRoot:Add('type':u, 'string':u).
                schemaRoot:Add('type':u, 'binary':u).
            end.

            otherwise
            // binary formats
            case mimeType[1]:
                when 'audio' or
                when 'image' or
                when 'video' then
                do:
                    schemaRoot:Add('type':u, 'string':u).
                    schemaRoot:Add('type':u, 'binary':u).
                end.
            end case.   //content type
        end case.   // content subtype
    end method.

    /* Writes the an operation

       @param DataObjectService The parent service
       @param MappedOperation The mapped operation */
    method override protected void WriteOperation(input pService as DataObjectService,
                                                  input pData as MappedOperation ):
        define variable childObj as JsonObject no-undo.
        define variable operJson as JsonObject no-undo.
        define variable contentJson as JsonObject no-undo.
        define variable iter as IIterator no-undo.
        define variable opParam as OperationParameter no-undo.
        define variable loop as integer no-undo.
        define variable cnt as integer no-undo.
        define variable operSchema as handle no-undo.
        define variable schemaRef as character no-undo.
        define variable requestBody as JsonObject no-undo.
        define variable operResponse as JsonObject no-undo.
        define variable parameters as JsonArray no-undo.

        assign operJson = GetPathJson(pService, pData:ServiceURI, pData:Method).

        operJson:Set('summary':u, pData:Name).
        case pData:TargetType:
            when string(TargetTypeEnum:File) then
                operJson:Set('operationId':u, substitute('&2:&1':u, entry(num-entries(pData:TargetName, '/':u), pData:TargetName, '/':u), pData:TargetType)).
            when string(TargetTypeEnum:Procedure) then
                operJson:Set('operationId':u, substitute('&3:&1+&2':u, entry(num-entries(pData:TargetName, '/':u), pData:TargetName, '/':u), pData:TargetFunction, pData:TargetType)).
            otherwise
                operJson:Set('operationId':u, substitute('&3:&1+&2':u, pData:TargetName, pData:TargetFunction, pData:TargetType)).
        end case.

        operJson:GetJsonArray('tags':u):Add(pService:Name).

        //responses
        assign operResponse = PropertyHelper:GetObjectValue(operJson:GetJsonObject('responses':u), string(pData:StatusCode, '999':u))
               contentJson  = PropertyHelper:GetObjectValue(operResponse, 'content':u)
               contentJson  = PropertyHelper:GetObjectValue(contentJson,  pData:ContentType)
               .
        operResponse:Add('description':u, substitute('&1 &2 operation for service &3 v&4':u,
                                                    string(pData:Method),
                                                    pData:ServiceURI,
                                                    pService:Name,
                                                    string(pService:Version))).

        // if this is a catalog, then we write the schema and a reference to it
        if pData:TargetType eq string(TargetTypeEnum:File) then
            WriteFileSchema(pData, contentJson).

        //Headers & Cookies
        WriteHeaders(pData:Headers, PropertyHelper:GetObjectValue(operResponse, 'headers':u)).
        if pData:Cookies:Size gt 0 then
        do:
            assign childObj = new JsonObject().
            childObj:Add('description':u, '':u).
            childObj:Add('type':u,        'string':u).
            childObj:Add('example':u,     'JSESSIONID=abcde12345; Path=/; HttpOnly':u).
            PropertyHelper:GetObjectValue(operResponse, 'headers':u):Add('Set-Cookie':u, childObj).
        end.    // indicate that cookies are coming back

        // if we use the return value, write those
        if valid-object(pData:ReturnValue) then
            assign cnt = extent(pData:ReturnValue:OutputElement).
        do loop = 1 to cnt:
            WriteResponseElements(pData:ReturnValue:OutputElement[loop],
                                  pData:ReturnValue,
                                  pData,
                                  contentJson).
        end.    // RETURN values

        // PARAMETERS, INPUT and OUTPUT elements in a single loop
        assign iter = pData:Parameters:Iterator().
        do while iter:HasNext():
            assign opParam  = cast(iter:Next(), OperationParameter).

            //INPUTS - PARAMETERS & BODY
            assign cnt = extent(opParam:InputElement).
            do loop = 1 to cnt:
                // Parameters can only be "query", "header", "path" or "cookie".
                case opParam:InputElement[loop]:ElementType:
                    when ElementTypeEnum:Query  or
                    when ElementTypeEnum:Header or
                    when ElementTypeEnum:Cookie or
                    when ElementTypeEnum:Path   then
                    do:
                        // if we're here, we have at least one parameter
                        if not valid-object(parameters) then
                            assign parameters = PropertyHelper:GetArrayValue(operJson, 'parameters':u).

                        assign childObj = new JsonObject().
                        parameters:Add(childObj).
                            childObj:Add('in':u,        lc(string(opParam:InputElement[loop]:ElementType))).
                            childObj:Add('name':u,      opParam:InputElement[loop]:ElementName).
                            childObj:Add('required':u, (opParam:InputElement[loop]:ElementType eq ElementTypeEnum:Path)).
                            childObj:Add('schema':u,    WriteElementSchema(opParam:InputElement[loop],
                                                                           opParam,
                                                                           pData)).
                    end.    // input parameters

                    when ElementTypeEnum:Field then
                    do:
                        if not valid-object(requestBody) then
                            assign requestBody = PropertyHelper:GetObjectValue(operJson,    'requestBody':u)
                                   requestBody = PropertyHelper:GetObjectValue(requestBody, 'content':u)
                                   requestBody = PropertyHelper:GetObjectValue(requestBody, pData:ContentType)
                                   .
                        WriteFieldSchema(opParam:InputElement[loop],
                                         opParam,
                                         pData,
                                         PropertyHelper:GetObjectValue(requestBody, 'schema':u)).
                    end.

                    when ElementTypeEnum:Body then
                    do:
                        if not valid-object(requestBody) then
                            assign requestBody = PropertyHelper:GetObjectValue(operJson,    'requestBody':u)
                                   requestBody = PropertyHelper:GetObjectValue(requestBody, 'content':u)
                                   requestBody = PropertyHelper:GetObjectValue(requestBody, pData:ContentType)
                                   .
                        // first time adding
                        if not requestBody:Has('schema':u) then
                            requestBody:Add('schema':u,
                                            WriteElementSchema(opParam:InputElement[loop],
                                                               opParam,
                                                               pData)).
                        else
                            WriteFieldSchema(opParam:InputElement[loop],
                                             opParam,
                                             pData,
                                             requestBody:GetJsonObject('schema':u)).
                    end.    //ElementTypeEnum:Body
                end case.
            end.    // input elements

            // now outputs
            assign cnt = extent(opParam:OutputElement).
            do loop = 1 to cnt:
                WriteResponseElements(opParam:OutputElement[loop],
                                      opParam,
                                      pData,
                                      contentJson).
            end.        //output elements
        end.    // parameters

        // add envelopes
        if pData:Options:HasRequestEnvelope then
            WriteEnvelope(pData:Options:RequestEnvelope, requestBody).

        if pData:Options:HasResponseEnvelope then
            WriteEnvelope(pData:Options:ResponseEnvelope, contentJson).
    end method.

    /* Writes FIELD and BODY outputs into a responses/content/<content-type>/ property

       @param MessageElement The element being written
       @param OperationParameter The element's parent
       @param MappedOperation The parameter's parent
       @param JsonObject The root object into which to write the element(s).    */
    method protected void WriteResponseElements(input pElement as MessageElement,
                                                input pParameter as OperationParameter,
                                                input pOperation as MappedOperation,
                                                input pSchemaRoot as JsonObject):
        case pElement:ElementType:
            when ElementTypeEnum:Field then
                WriteFieldSchema(pElement,
                                 pParameter,
                                 pOperation,
                                 PropertyHelper:GetObjectValue(pSchemaRoot, 'schema':u)).

            when ElementTypeEnum:Body then
            do:
                // first time adding
                if not pSchemaRoot:Has('schema':u) then
                    pSchemaRoot:Add('schema':u,
                                    WriteElementSchema(pElement,
                                                       pParameter,
                                                       pOperation)).
                else
                    WriteFieldSchema(pElement,
                                     pParameter,
                                     pOperation,
                                     pSchemaRoot:GetJsonObject('schema':u)).
            end.    //ElementTypeEnum:Body
        end case.
    end method.

    /* Writes a dataset schema

       @param handle     A valid dataset handle
       @param JsonObject The schema root for writing the schemas into. This should NOT include path
       @param logical    TRUE if tables should be written as references */
    method protected void WriteDataset(input pDataset as handle,
                                       input pSchemaRoot as JsonObject,
                                       input pWriteRef as logical):
        define variable loop as integer no-undo.
        define variable cnt as integer no-undo.
        define variable childData as JsonObject no-undo.
        define variable datasetJson as JsonObject no-undo.
        define variable tableJson as JsonObject no-undo.
        define variable bufferHdl as handle no-undo.
        define variable propsJson as JsonObject no-undo.
        define variable schemaRoot as JsonObject no-undo.
        define variable schemaName as character no-undo.

        if not valid-handle(pDataset) then
            return.

        Assert:NotNull(pSchemaRoot, 'Schema root').

        // It's already added to the datasets
        assign schemaRoot = pSchemaRoot
               schemaName = pDataset:serialize-name
               .
        if schemaRoot:Has(schemaName) then
            return.

        assign datasetJson = PropertyHelper:GetObjectValue(schemaRoot, schemaName)
               propsJson   = new JsonObject()
               childData   = new JsonObject()
               cnt         = pDataset:num-buffers
               .
        datasetJson:Add('type':u, 'object':u).
        datasetJson:Add('additionalProperties':u, false).
        datasetJson:Add('properties':u, propsJson).
            propsJson:Add(pDataset:serialize-name, childData).
                childData:Add('type':u, 'object':u).
                childData:Add('additionalProperties':u, false).

        assign propsJson = new JsonObject().
                childData:Add('properties':u, propsJson).

        //parent for tables' schemas
        if not pWriteRef then
            assign schemaRoot = propsJson.

        do loop = 1 to cnt:
            assign bufferHdl = pDataset:get-buffer-handle(loop).
            WriteTable(bufferHdl, schemaRoot).

            // Add a reference if needed
            if pWriteRef then
            do:
                assign tableJson = new JsonObject().
                tableJson:Add('$ref':u, '#/components/schemas/':u + bufferHdl:serialize-name).
                propsJson:Add(bufferHdl:serialize-name, tableJson).
            end.
        end.
    end method.

    /* Writes a temp-table schema

       @param handle A valid temp-table handle
       @param JsonObject The schema root */
    method protected void WriteTable(input pTable as handle,
                                     input pSchemaRoot as JsonObject):
        define variable loop as integer no-undo.
        define variable cnt as integer no-undo.
        define variable idx as integer no-undo.
        define variable tableJson as JsonObject no-undo.
        define variable fldJson as JsonObject no-undo.
        define variable itemsJson as JsonObject no-undo.
        define variable childObj as JsonObject no-undo.
        define variable bufferFld as handle no-undo.
        define variable fldFormat as character no-undo.
        define variable fldType as character no-undo.
        define variable propsJson as JsonObject no-undo.
        define variable uniqueFld as character no-undo.
        define variable idxInfo as character no-undo.
        define variable delim as character no-undo.
        define variable reqFlds as JsonArray no-undo.

        if not valid-handle(pTable) then
            return.

        Assert:NotNull(pSchemaRoot, 'Schema root').
        // don't try to re-add
        if pSchemaRoot:Has(pTable:serialize-name) then
            return.

        // determine required fields -> those that are in a unique index
        assign idx     = 1
               idxInfo = pTable:index-information(idx)
               .
        do while not idxInfo eq ?:
            if entry(2, idxInfo) eq '1':u then
            do:
                // index fields
                assign cnt = num-entries(idxInfo).
                do loop = 5 to cnt by 2:
                    if entry(loop, idxInfo) eq '':u then
                        next.
                    assign uniqueFld = uniqueFld + delim + entry(loop, idxInfo)
                           delim     = ',':u
                           .
                end.
            end.
            assign idx     = idx + 1
                   idxInfo = pTable:index-information(idx)
                   .
        end.

        assign tableJson = PropertyHelper:GetObjectValue(pSchemaRoot, pTable:serialize-name)
               itemsJson = new JsonObject()
               propsJson = new JsonObject()
               reqFlds   = new JsonArray()
               cnt       = pTable:num-fields
               .
        tableJson:Add('type':u, 'array':u).
        tableJson:Add('items':u, itemsJson).
            itemsJson:Add('additionalProperties':u, false).
            itemsJson:Add('properties':u, propsJson).

        do loop = 1 to cnt:
            assign bufferFld = pTable:buffer-field(loop).

            // not visible to the outside world
            if bufferFld:serialize-hidden then
                next.

            /* Create the new field object. */
            assign fldJson = new JsonObject()
                   .
            propsJson:Add(bufferFld:serialize-name, fldJson).

            assign fldType = FieldInfo(bufferFld:data-type,
                                       output fldFormat).

            if bufferFld:extent gt 0 then
            do:
                fldJson:Add('type':u, 'array':u).
                fldJson:Add('title':u, bufferFld:label).
                fldJson:Add('maxItems':u, bufferFld:extent).
                assign childObj = new JsonObject().
                fldJson:Add('items':u, childObj).
                    childObj:Add('type':u, fldType).
                    childObj:Add('nullable':u, true).
                    if lookup(bufferFld:name, uniqueFld) gt 0 then
                        reqFlds:Add(bufferFld:serialize-name).

                    if not fldFormat eq '':u then
                        childObj:Add('format':u, fldFormat ).

                    WriteDefaultFieldValue(bufferFld, childObj).
            end. /* Extent */
            else
            do:
                fldJson:Add('title':u, bufferFld:label).
                fldJson:Add('type':u,  fldType).
                fldJson:Add('nullable':u, true).
                if lookup(bufferFld:name, uniqueFld) gt 0 then
                    reqFlds:Add(bufferFld:serialize-name).
                if not fldFormat eq '':u then
                    fldJson:Add('format':u, fldFormat ).

                WriteDefaultFieldValue(bufferFld, fldJson).
            end. /* Normal */
            delete object bufferFld.
        end. /* num-fields */

        // don't add required fields if there aren't any
        if reqFlds:Length gt 0 then
            itemsJson:Add('required':u, reqFlds).
    end method.

    /* Writes the correctly-typed default value for a field

       @param handle A valid buffer-field handle
       @param JsonObject A valid JSON object representing the field */
    method protected void WriteDefaultFieldValue(input pField as handle,
                                                 input pJson as JsonObject):
        if not valid-handle(pField)
           or not valid-object(pJson)
        then
            return.

        if pField:default-value eq ? then
            pJson:AddNull('default':u).
        else
        case pField:data-type:
            when 'date':u then
                //date-fullyear "-" date-month "-" date-mday
                pJson:Add('default':u, substitute('&1-&2-&3':u,
                                    string(year(pField:default-value),  '9999':u),
                                    string(month(pField:default-value), '99':u),
                                    string(day(pField:default-value),   '99':u))).

            when 'datetime':u or
            when 'datetime-tz':u then
                pJson:Add('default':u, iso-date(pField:default-value)).

            when 'integer':u or
            when 'int64':u then
                pJson:Add('default':u, int64(pField:default-value)).

            when 'decimal':u then
                pJson:Add('default':u, decimal(pField:default-value)).

            when 'logical':u then
                pJson:Add('default':u, logical(pField:default-value)).

            when 'blob':u or
            when 'raw':u then
                pJson:AddNull('default':u).

            otherwise
                pJson:Add('default':u, string(pField:default-value)).
        end case.
    end method.

    /* Returns JSON type and format information for an ABL type

       @param character An ABL type (primitive)
       @param character OUTPUT The JSON format for the data type
       @return character The JSON data type */
    method protected character FieldInfo (input  pAblType as character,
                                          output pFormat as character):
        define variable fldType as character no-undo.

        case pAblType:
            when 'date':u then
                assign fldType = 'string':u
                       pFormat = 'date':u
                       .
            when 'datetime':u or
            when 'datetime-tz':u then
                assign fldType = 'string':u
                       pFormat = 'date-time':u
                       .
            when 'character':u or
            when 'clob':u or
            when 'longchar' then
                assign fldType = 'string':u
                       pFormat = '':u
                       .
            when 'integer':u then
                assign fldType = 'integer':u
                       pFormat = 'int32':u
                       .
            when 'int64':u then
                assign fldType = 'integer':u
                       pFormat = 'int64':u
                       .
            when 'decimal':u then
                assign fldType = 'number':u
                       pFormat = '':u
                       .
            when 'logical':u then
                assign fldType = 'boolean':u
                       pFormat = '':u
                       .
            when 'blob':u or
            when 'raw':u then
                assign fldType = 'string':u
                       pFormat = 'binary':u
                       .
            when 'rowid':u then
                assign fldType = 'string':u
                       pFormat = '0x<hex-digits>':u
                       .
            otherwise
                assign fldType = 'string':u
                       pFormat = '':u
                       .
        end case.

        return fldType.
    end method.

    /* Writes a schema into the #/components/schemas section

       @param DataObjectService The parent service
       @param handle A valid schema handle */
    method override protected void WriteSchema(input pService as DataObjectService,
                                               input pData as handle ):
        define variable schemaRoot as JsonObject no-undo.

        if not valid-handle(pData) then
            return.

        assign schemaRoot = cast(this-object:Value, JsonObject)
                                :GetJsonObject('components':u)
                                :GetJsonObject('schemas':u).

        case pData:type:
            when 'dataset':u then
                WriteDataset(pData, schemaRoot, true).
            when 'buffer':u then
                WriteTable(pData, schemaRoot).
            when 'table':u or
            when 'temp-table':u then
                WriteTable(pData:default-buffer-handle, schemaRoot).
        end case.
    end method.

    /* Writes a tag

       @param character REQUIRED Thye tag name
       @param character The tag sescription
       @param JsonObject Optioanl external documentation data */
    method protected void WriteTag(input pName as character,
                                   input pDescription as character,
                                   input pExtDoc as JsonObject):
        define variable tagArray as JsonArray no-undo.
        define variable tagData as JsonObject no-undo.
        define variable loop as integer no-undo.
        define variable cnt as integer no-undo.
        define variable tagExists as logical no-undo.

        assign tagArray  = cast(this-object:Value, JsonObject):GetJsonArray('tags':u)
               cnt       = tagArray:Length
               tagExists = no
               .
        do loop = 1 to cnt while not tagExists:
            assign tagData   = tagArray:GetJsonObject(loop)
                   tagExists = tagData:GetCharacter('name':u) eq pName
                   .
        end.

        if tagExists then
        do:
            tagData:Set('description':u, pDescription).
            if valid-object(pExtDoc) then
                tagData:Set('externalDocs':u, pExtDoc).
        end.
        else
        do:
            assign tagData = new JsonObject().
            tagArray:Add(tagData).
                tagData:Add('name':u, pName).
                tagData:Add('description':u, pDescription).
            if valid-object(pExtDoc) then
                tagData:Add('externalDocs':u, pExtDoc).
        end.
    end method.

    /* Writes a Data Object Service

       @param DataObjectService The service to write */
    method override protected void WriteService(input pData as DataObjectService):
        if not valid-object(pData) then
            return.

        WriteTag(pData:Name,
                 substitute('Service for &1 v&2',
                                trim(pData:Name, '/':u), string(pData:Version)),
                 ?).
    end method.

    /* Writes a URI to the output

       @param URI The URI to write */
    method override protected void WriteURI(input pData as URI):
        define variable servers as JsonArray no-undo.
        define variable svr as JsonObject no-undo.

        if not valid-object(pData) then
            return.

        assign servers = cast(this-object:Value, JsonObject):GetJsonArray('servers':u)
               svr     = new JsonObject()
               .
        servers:Add(svr).
        svr:Add('url':u, pData:ToString()).
        svr:Add('description':u, 'Server configuration':u).
    end method.

    /* Writes a tuple (key-value pair).
       This is effectively a VIRTUAL method (no default behaviour but not compiled enforcement either).

       @param Progress.Lang.Object The key value - property name (required)
       @param Progress.Lang.Object A value to be written for the property. May be null. */
    method override protected void WriteTuple(input pKey as Progress.Lang.Object,
                                              input pValue as Progress.Lang.Object):
        define variable parent as JsonObject no-undo.
        define variable securitySchemes as JsonObject no-undo.
        define variable inputSchemes as JsonObject no-undo.
        define variable loop as integer no-undo.
        define variable cnt as integer no-undo.
        define variable names as longchar extent no-undo.
        define variable propName as character no-undo.
        define variable stringValue as character no-undo.

        if not valid-object(pValue) then
            return.

        case pKey:ToString():
            when 'info.version':u or
            when 'info.title':u or
            when 'info.description':u or
            when 'info.termsOfService':u then
            do:
                assign propName = entry(2, pKey:ToString(), '.':u)
                       parent   = PropertyHelper:GetObjectValue(cast(this-object:Value, JsonObject), 'info':u)
                       .
                if parent:Has(propName) then
                    parent:Set(propName, pValue:ToString()).
                else
                    parent:Add(propName, pValue:ToString()).
            end.    //string-based data: title, desc, TOS etc

            when 'info.contact':u or
            when 'info.license':u then
            do:
                if type-of(pValue, JsonObject) then
                do:
                    assign propName = entry(2, pKey:ToString(), '.':u)
                           parent   = PropertyHelper:GetObjectValue(cast(this-object:Value, JsonObject), 'info':u)
                           .
                    if parent:Has(propName) then
                        parent:Set(propName, cast(pValue, JsonObject)).
                    else
                        parent:Add(propName, cast(pValue, JsonObject)).
                end.
            end.    // JSON-based data: license, contact etc

            when 'securitySchemes':u then
            do:
                if type-of(pValue, JsonObject) then
                do:
                    assign inputSchemes    = cast(pValue, JsonObject)
                           parent          = PropertyHelper:GetObjectValue(cast(this-object:Value, JsonObject), 'components':u)
                           securitySchemes = PropertyHelper:GetObjectValue(parent, 'securitySchemes':u)
                           names           = inputSchemes:GetNames()
                           cnt             = extent(names)
                           .
                    do loop = 1 to cnt:
                        securitySchemes:Add(string(names[loop]),
                                            inputSchemes:GetJsonObject(string(names[loop]))).
                    end.
                end.
            end.
        end case.
    end method.

    /* Adds an envelope to the request or response body

       @param character The envelope to add
       @param JsonObject The current body schema */
    method protected void WriteEnvelope(input pEnvelope as character,
                                        input pBody as JsonObject):
        define variable wrappedBody as JsonObject no-undo.
        define variable schemaData as JsonObject no-undo.
        define variable props as JsonObject no-undo.

        if String:IsNullOrEmpty(pEnvelope) then
            return.

        assign schemaData  = PropertyHelper:GetObjectValue(pBody, 'schema':u)
               props       = PropertyHelper:GetObjectValue(schemaData, 'properties':u)
               wrappedBody = new JsonObject()
               .
        // delete the old values
        schemaData:Remove('properties':u).
        // add the new envelope property as the only property
        PropertyHelper:GetObjectValue(schemaData, 'properties':u)
                :Add(pEnvelope, wrappedBody).

        // now add the previous properties as properties to the wrapper
        // props has all of the existing proeprties for this schema
        wrappedBody:Add('type':u,       'object':u).
        wrappedBody:Add('properties':u, props).
    end method.

    /* Writes JSON for a message field element (request or response)

       @param  MessageElement The message element
       @param  OperationParameter The (parent) Parameter
       @return JsonObject the JSON for this field element */
    method protected void WriteFieldSchema(input pElement as MessageElement,
                                           input pParameter as OperationParameter,
                                           input pOperation as MappedOperation,
                                           input pSchemaRoot as JsonObject   ):
        define variable propsJson as JsonObject no-undo.
        define variable jsonData as JsonObject no-undo.
        define variable schemaRef as character no-undo.

        assign propsJson = PropertyHelper:GetObjectValue(pSchemaRoot, 'properties':u).
        if not pSchemaRoot:Has('type':u) then
            pSchemaRoot:Add('type':u, 'object':u).

        if pSchemaRoot:Has('$ref':u) then
        do:
            assign jsonData  = new JsonObject()
                   schemaRef = pSchemaRoot:GetCharacter('$ref':u)
                   .
            jsonData:Add('$ref':u, schemaRef).
            propsJson:Add(pElement:ElementName, jsonData).
            // move to the 'properties' element
            pSchemaRoot:Remove('$ref':u).
        end.

        propsJson:Add(pElement:ElementName,
                      WriteElementSchema(pElement,
                                         pParameter,
                                         pOperation)).
    end method.

    /* Writes JSON for a message body element (request or response)

       @param  MessageElement The message element
       @param  OperationParameter The (parent) Parameter
       @return JsonObject the JSON for this field element */
    method protected JsonObject WriteElementSchema(input pElement as MessageElement,
                                                   input pParameter as OperationParameter,
                                                   input pOperation as MappedOperation):
        define variable fldJson as JsonObject no-undo.
        define variable fldFormat as character no-undo.
        define variable dataSchema as handle no-undo.

        assign fldJson = new JsonObject().
        if pParameter:HasSchema then
        do:
            // if this operation has its own schema, write that directly, else use a reference
            assign dataSchema = pOperation:GetSchema(pParameter:ABLName).
            case pParameter:DataType:
                when 'dataset':u or
                when 'dataset-handle':u then
                do:
                    if valid-handle(dataSchema) then
                        WriteDataset(dataSchema, fldJson, ?).
                    else
                        fldJson:Add('$ref':u, '#/components/schemas/':u + pParameter:ABLName).
                end.

                when 'table':u or
                when 'table-handle':u then
                do:
                    if valid-handle(dataSchema) then
                        WriteTable(dataSchema, fldJson).
                    else
                        fldJson:Add('$ref':u, '#/components/schemas/' + pParameter:ABLName).
                end.
            end case.
        end.    //has a schema
        else
        do:
            case pParameter:DataType:
                when 'handle':u then
                    fldJson:Add('type':u, FieldInfo('int64', output fldFormat)).
                when 'class':u then
                do:
                    fldJson:Add('type':u, 'object').
                    assign fldFormat = '':u.
                end.
                otherwise
                    fldJson:Add('type':u, FieldInfo(pParameter:DataType, output fldFormat)).
            end case.

            if not fldFormat eq '':u then
                fldJson:Add('format':u, fldFormat).
        end.

        return fldJson.
    end method.

end class.