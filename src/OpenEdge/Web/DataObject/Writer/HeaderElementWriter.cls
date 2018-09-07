/* *************************************************************************************************************************
Copyright (c) 2018 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
************************************************************************************************************************** */
 /*------------------------------------------------------------------------
    File        : HeaderElementWriter
    Description : Writes message elements as a cookie
    Author(s)   : pjudge
    Created     : 2018-05-08
    Notes       : 
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using Ccs.Common.Support.ICharacterHolder.
using Ccs.Common.Support.ILongcharHolder.
using OpenEdge.Core.Assert.
using OpenEdge.Core.IObjectArrayHolder.
using OpenEdge.Core.KeyValuePair.
using OpenEdge.Net.HTTP.HttpHeader.
using OpenEdge.Net.HTTP.HttpHeaderBuilder.
using OpenEdge.Net.HTTP.IHttpResponse.
using OpenEdge.Web.DataObject.ElementTypeEnum.
using OpenEdge.Web.DataObject.MessageElement.
using OpenEdge.Web.DataObject.Writer.ResponseElementWriter.

class OpenEdge.Web.DataObject.Writer.HeaderElementWriter inherits ResponseElementWriter: 
    
    /** Default constructor. */
    constructor public HeaderElementWriter():
        super().
    end constructor.
    
    /** Constructor.
        
        @param IHttpResponse The response being written to */
    constructor public HeaderElementWriter(input pResponse as IHttpResponse):
        super(pResponse).
    end constructor.
    
    /* Writes message element data to the response
       
       @param character The element name 
       @param Progress.Lang.Object The data to write */
    method override public void Write(input pElemName as character,
                                      input pElemValue as Progress.Lang.Object):
        define variable headers as Progress.Lang.Object extent no-undo.
        define variable loop as integer no-undo.
        define variable cnt as integer no-undo.
        define variable hdrValue as character no-undo.
        
        case true:
            when not valid-object(pElemValue) then
                return.
            
            when type-of(pElemValue, IObjectArrayHolder) or
            when type-of(pElemValue, HttpHeader) then
                this-object:Write(pElemValue).
            
            when type-of(pElemValue, ILongcharHolder) or
            when type-of(pElemValue, ICharacterHolder) then
            do:
                assign hdrValue = string(dynamic-property(pElemValue, 'Value':u)).
                
                this-object:Response:SetHeader(HttpHeaderBuilder
                                                    :Build(pElemName)
                                                    :Value(hdrValue)
                                                    :Header).
            end.
        end case.
    end method.
    
    method override public void Write(input pElemValue as Progress.Lang.Object ):
        define variable headers as Progress.Lang.Object extent no-undo.
        
        case true:
            when not valid-object(pElemValue) then
                return.
            
            when type-of(pElemValue, IObjectArrayHolder) then
            do:
                assign headers = cast(pElemValue, IObjectArrayHolder):Value.
                if extent(headers) eq ? then
                    return.
                
                Assert:IsType(headers, get-class(HttpHeader)).
                this-object:Response:SetHeaders(cast(headers, HttpHeader)).
            end.
            
            when type-of(pElemValue, KeyValuePair) then
                this-object:Write(cast(pElemValue, KeyValuePair):Key:ToString(), cast(pElemValue, KeyValuePair):Value).
            
            when type-of(pElemValue, HttpHeader) then
                this-object:Response:SetHeader(cast(pElemValue, HttpHeader)).
            
            otherwise
                Logger:Warn(substitute('Cannot convert message element type &1 to &2',
                                pElemValue:GetClass():TypeName,
                                string(ElementTypeEnum:Header))).
        end case.
    end method.

end class.