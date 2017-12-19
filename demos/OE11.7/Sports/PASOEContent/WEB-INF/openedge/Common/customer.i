/*------------------------------------------------------------------------
   File        : Customer
   Purpose     :
   Syntax      :
   Description :
   Author(s)   : Code Wizard
   Created     : 08/01/16
   Notes       :
 ----------------------------------------------------------------------*/

@openapi.openedge.entity.primarykey(fields="CustNum").
@openapi.openedge.entity.field.property(field="id", name="semanticType", value="Internal").
@openapi.openedge.entity.field.property(field="seq", name="semanticType", value="Internal").
@openapi.openedge.entity.field.property(field="Name", name="editable", value="false").
@openapi.openedge.entity.field.property(field="Phone", name="semanticType", value="PhoneNumber").
@openapi.openedge.entity.field.property(field="Balance", name="semanticType", value="Currency").
@openapi.openedge.entity.field.property(field="CreditLimit", name="semanticType", value="Currency").
@openapi.openedge.entity.foreignkey(name="SalesrepFK", fields="SalesRep", parent="salesrep.ttSalesrep", parentFields="SalesRep").

define temp-table ttCustomer no-undo before-table bttCustomer
    field id           as character
    field seq          as integer   initial ?
    field CustNum      as integer   label "Cust Num" initial 0
    field Name         as character label "Name" serialize-name "CustName"
    field Address      as character label "Address"
    field Address2     as character label "Address2"
    field City         as character label "City"
    field State        as character label "State"
    field PostalCode   as character label "Postal Code"
    field Country      as character label "Country" initial "USA"
    field Contact      as character label "Contact"
    field Phone        as character label "Phone"
    field SalesRep     as character label "Sales Rep"
    field CreditLimit  as decimal   label "Credit Limit" initial 1500
    field Balance      as decimal   label "Balance" initial 0
    field Terms        as character label "Terms" initial "Net30"
    field Discount     as integer   label "Discount" initial 0
    field Comments     as character label "Comments"
    field Fax          as character label "Fax"
    field EmailAddress as character label "Email"
    index pkSeq        is primary unique seq
    index idxComments             Comments
    index idxCountryPost          Country PostalCode
    index idxCustNum   is unique  CustNum
    index idxName                 Name
    index idxSalesRep             SalesRep
    .

define dataset dsCustomer for ttCustomer.

