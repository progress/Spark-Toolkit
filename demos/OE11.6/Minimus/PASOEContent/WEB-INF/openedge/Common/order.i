/*------------------------------------------------------------------------
    File        : OrderBE
    Purpose		:
    Syntax      :
    Description :
    Author(s)   : Dustin Grau
    Created     : Wed Sep 20 07:49:22 EDT 2017
    Notes       :
  ----------------------------------------------------------------------*/

@openapi.openedge.entity.primarykey (fields="Ordernum").
@openapi.openedge.entity.field.property (field="id", name="semanticType", value="Internal").
@openapi.openedge.entity.field.property (field="seq", name="semanticType", value="Internal").

define temp-table ttOrder before-table bttOrder
    field id           as character
    field seq          as integer   initial ?
    field Ordernum     as integer   initial "0" label "Order Num"
    field CustNum      as integer   initial "0" label "Cust Num"
    field OrderDate    as date      initial "TODAY" label "Ordered"
    field ShipDate     as date      label "Shipped"
    field PromiseDate  as date      label "Promised"
    field Carrier      as character label "Carrier"
    field Instructions as character label "Instructions"
    field PO           as character label "PO"
    field Terms        as character initial "Net30" label "Terms"
    field SalesRep     as character label "Sales Rep"
    field BillToID     as integer   initial "0" label "Bill To ID"
    field ShipToID     as integer   initial "0" label "Ship To ID"
    field OrderStatus  as character initial "Ordered" label "Order Status"
    field WarehouseNum as integer   initial "0" label "Warehouse Num"
    field Creditcard   as character initial "Visa" label "Credit Card"
    index seq is primary unique seq
    index CustOrder is unique   CustNum     ascending Ordernum ascending
    index OrderDate             OrderDate   ascending
    index OrderNum is unique    Ordernum    ascending
    index OrderStatus           OrderStatus ascending
    index SalesRep              SalesRep    ascending
    .

@openapi.openedge.entity.primarykey (fields="Ordernum").
@openapi.openedge.entity.field.property (field="id", name="semanticType", value="Internal").
@openapi.openedge.entity.field.property (field="seq", name="semanticType", value="Internal").

define temp-table ttOrderLine before-table bttOrderLine
    field Ordernum        as integer   initial "0" label "Order Num"
    field Linenum         as integer   initial "0" label "Line Num"
    field Itemnum         as integer   initial "0" label "Item Num"
    field Price           as decimal   initial "0" label "Price"
    field Qty             as integer   initial "0" label "Qty"
    field Discount        as integer   initial "0" label "Discount"
    field ExtendedPrice   as decimal   initial "0" label "Extended Price"
    field OrderLineStatus as character initial "Ordered" label "Order Line Status"
    index itemnum                     Itemnum         ascending
    index orderline is primary unique Ordernum        ascending Linenum ascending
    index OrderLineStatus             OrderLineStatus ascending
    .

define dataset dsOrder for ttOrder, ttOrderLine
    data-relation OrderLines for ttOrder, ttOrderLine relation-fields(OrderNum,OrderNum) nested.
