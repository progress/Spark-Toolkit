/*------------------------------------------------------------------------
    File        : order.i
    Purpose     :
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Thu May 28 10:42:09 EDT 2015
    Notes       :
  ----------------------------------------------------------------------*/

@openapi.openedge.entity.primarykey(fields="Ordernum").
@openapi.openedge.entity.field.property(field="id", name="semanticType", value="Internal").
@openapi.openedge.entity.field.property(field="seq", name="semanticType", value="Internal").
@openapi.openedge.entity.foreignkey(name="SalesrepFK", fields="SalesRep", parent="salesrep.ttSalesrep", parentFields="SalesRep").

define temp-table ttOrder no-undo before-table bttOrder
    field id           as character
    field seq          as integer
    field OrderNum     as integer   label "Order Num" initial 0
    field CustNum      as integer   label "Cust Num" initial 0
    field OrderDate    as date      label "Ordered" initial today
    field ShipDate     as date      label "Shipped"
    field PromiseDate  as date      label "Promised"
    field Carrier      as character label "Carrier"
    field Instructions as character label "Instructions"
    field PO           as character label "PO"
    field Terms        as character label "Terms" initial "Net30"
    field SalesRep     as character label "Sales Rep"
    field BillToID     as integer   label "Bill To ID" initial 0
    field ShipToID     as integer   label "Ship To ID" initial 0
    field OrderStatus  as character label "Order Status" initial "Ordered"
    field WarehouseNum as integer   label "Warehouse Num" initial 0
    field Creditcard   as character label "Credit Card" initial "Visa"
    field CustName     as character label "Customer Name"
    field SalesRepName as character label "Sales Rep Name"
    index seq          is primary unique seq
    index CustOrder    is unique  CustNum     ascending Ordernum ascending
    index OrderDate               OrderDate   ascending
    index OrderNum     is unique  OrderNum    ascending
    index OrderStatus             OrderStatus ascending
    index SalesRep                SalesRep    ascending
    .

@openapi.openedge.entity.primarykey(fields="Ordernum").
@openapi.openedge.entity.field.property(field="id", name="semanticType", value="Internal").
@openapi.openedge.entity.field.property(field="seq", name="semanticType", value="Internal").

define temp-table ttOrderLine no-undo before-table bttOrderLine
    field OrderNum        as integer   initial "0" label "Order Num"
    field LineNum         as integer   initial "0" label "Line Num"
    field ItemNum         as integer   initial "0" label "Item Num"
    field Price           as decimal   initial "0" label "Price"
    field Qty             as integer   initial "0" label "Quantity"
    field Discount        as integer   initial "0" label "Discount"
    field ExtendedPrice   as decimal   initial "0" label "Extended Price"
    field OrderLineStatus as character initial "Ordered" label "Order Line Status"
    field ItemName        as character label "Item Name"
    index OrderLine       is primary unique OrderNum Linenum
    index ItemNum                    ItemNum
    index OrderLineStatus            OrderLineStatus
    .

define dataset dsOrder for ttOrder, ttOrderLine
    data-relation OrderLines for ttOrder, ttOrderLine relation-fields(OrderNum,OrderNum) nested.
