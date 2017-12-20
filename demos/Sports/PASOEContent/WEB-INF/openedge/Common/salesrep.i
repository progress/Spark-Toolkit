/*------------------------------------------------------------------------
   File        : SalesRep
   Purpose     :
   Syntax      :
   Description :
   Author(s)   : Code Wizard
   Created     : 07/01/16
   Notes       :
 ----------------------------------------------------------------------*/

@openapi.openedge.entity.primarykey(fields="SalesRep").
@openapi.openedge.entity.field.property(field="id", name="semanticType", value="Internal").
@openapi.openedge.entity.field.property(field="seq", name="semanticType", value="Internal").
@openapi.openedge.entity.field.property(field="MonthQuota", name="semanticType", value="Currency").

define temp-table ttSalesrep no-undo before-table bttSalesrep
    field id           as character
    field seq          as integer   initial ?
    field SalesRep     as character label "Sales Rep"
    field RepName      as character label "Rep Name"
    field Region       as character label "Region"
    field MonthQuota   as integer   label "Month Quota" extent 12 initial 0
    index seq          is primary unique seq
    index SalesRep     is unique  SalesRep
    .

define dataset dsSalesrep for ttSalesrep.
