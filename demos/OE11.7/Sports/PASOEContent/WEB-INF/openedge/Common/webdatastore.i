/*------------------------------------------------------------------------
   File        : WebDataStore
   Purpose     :
   Syntax      :
   Description :
   Author(s)   : Code Wizard
   Created     : 08/04/16
   Notes       :
 ----------------------------------------------------------------------*/

@openapi.openedge.entity.primarykey(fields="WebSessionID,ObjectName").
@openapi.openedge.entity.field.property(field="id", name="semanticType", value="Internal").
@openapi.openedge.entity.field.property(field="seq", name="semanticType", value="Internal").

define temp-table ttWebDataStore no-undo
    field id           as character
    field seq          as integer   initial ?
    field WebSessionID as character label "SessionID"
    field ObjectName   as character label "Object"
    field ObjectData   as clob      label "Data"
    index pkSeq        is primary unique seq
    index idxpkData    is unique WebSessionID descending ObjectName descending
    .

define dataset dsWebDataStore for ttWebDataStore.
