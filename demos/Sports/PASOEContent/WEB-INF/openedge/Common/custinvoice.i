/*------------------------------------------------------------------------
    File        : CustInvoice
    Purpose        :
    Description :
    Author(s)   : bpadmin
    Created     : Wed Jul 20 10:08:59 EDT 2016
    Notes       :
  ----------------------------------------------------------------------*/

@openapi.openedge.entity.primarykey(fields="CustNum").
@openapi.openedge.entity.field.property(field="id", name="semanticType", value="Internal").
@openapi.openedge.entity.field.property(field="seq", name="semanticType", value="Internal").

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

define temp-table ttInvoice before-table bttInvoice
    field id          as character
    field seq         as integer   initial ?
    field Invoicenum  as integer   label "Invoice Num"
    field CustNum     as integer   label "Cust Num"
    field InvoiceDate as date      label "Invoice Date"
    field Amount      as decimal   label "Amount"
    field TotalPaid   as decimal   label "Total Paid"
    field Adjustment  as decimal   label "Adjustment"
    field OrderNum    as integer   label "Order Num"
    field ShipCharge  as decimal   label "Ship Charge"
    index pkSeq       is primary unique seq
    index idxCustNum              CustNum     descending
    index idxInvoiceDate          InvoiceDate descending
    index idxInvoiceNum is unique Invoicenum  descending
    index idxOrderNum             OrderNum    descending
    .

define dataset dsCustInvoice for ttCustomer, ttInvoice.
