/*------------------------------------------------------------------------
    File        : SalesrepBE
    Purpose		:
    Syntax      :
    Description :
    Author(s)   : Dustin Grau
    Created     : Wed Aug 30 09:07:04 EDT 2017
    Notes       :
  ----------------------------------------------------------------------*/

@openapi.openedge.entity.primarykey (fields="SalesRep").
@openapi.openedge.entity.field.property (field="id", name="semanticType", value="Internal").
@openapi.openedge.entity.field.property (field="seq", name="semanticType", value="Internal").
@openapi.openedge.entity.field.property (field="MonthQuota", name="semanticType", value="Currency").

define temp-table ttSalesrep before-table bttSalesrep
    field id         as character
    field seq        as integer   initial ?
    field SalesRep   as character label "Sales Rep"
    field RepName    as character label "Rep Name"
    field Region     as character label "Region"
    field MonthQuota as integer   extent 12 initial "0" label "Month Quota"
    index seq is primary unique seq
    index SalesRep is unique SalesRep ascending
    .

define dataset dsSalesrep for ttSalesrep.