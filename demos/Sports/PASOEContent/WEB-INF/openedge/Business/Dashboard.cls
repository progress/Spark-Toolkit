/*------------------------------------------------------------------------
    File        : Dashboard
    Purpose     : Class for Dashboard statistics
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Wed Jun 03 12:48:05 EDT 2015
    Notes       :
  ----------------------------------------------------------------------*/

@program FILE(name="Dashboard.cls", module="AppServer").
@openapi.openedge.export FILE(type="REST", executionMode="singleton", useReturnValue="false", writeDataSetBeforeImage="false").
@progress.service.resource FILE(name="dashboard", URI="/dashboard", schemaName="", schemaFile="").

using Progress.Lang.* from propath.
using Spark.Core.Manager.ISchemaManager from propath.

block-level on error undo, throw.

class Business.Dashboard inherits Spark.Core.Service.SparkEntity:

    {Common/dashboard.i}

    define private temp-table ttTopCust no-undo
        field CustNum  as integer
        field SalesAmt as decimal
        .

    define private temp-table ttTopRep no-undo
        field SalesRep as character
        field SalesAmt as decimal
        .

    define private temp-table ttTopCall no-undo
        field CustNum  as integer
        field NumCalls as integer
        .

    method private void getSalesStats ( ):
        define variable iLastYear  as integer no-undo.
        define variable dStartDate as date    no-undo.

        for last Order no-lock
              by Order.OrderDate:
            assign iLastYear = year(Order.OrderDate).
        end.

        assign dStartDate = date("1/1/" + string(iLastYear)).

        create salesPipeline.
        assign salesPipeline.category = "Back Order".
        for each Order no-lock
           where Order.OrderStatus eq "Shipped"
             and promisedate lt shipdate
             and Order.OrderDate ge dStartDate:
            for each OrderLine no-lock
               where OrderLine.OrderNum eq Order.OrderNum:
                assign salesPipeline.amount = salesPipeline.amount + (OrderLine.Price * OrderLine.Qty).
            end.
        end.
        release salesPipeline.

        create salesPipeline.
        assign salesPipeline.category = "Preparation".
        for each Order no-lock
           where Order.OrderStatus eq "Ordered"
             and Order.PromiseDate ne ?
             and Order.OrderDate ge dStartDate:
            for each OrderLine no-lock
               where OrderLine.OrderNum eq Order.OrderNum:
                assign salesPipeline.amount = salesPipeline.amount + (OrderLine.Price * OrderLine.Qty).
            end.
        end.
        release salesPipeline.

        create salesPipeline.
        assign salesPipeline.category = "Shipped".
        for each Order no-lock
           where Order.OrderStatus eq "Shipped"
             and promisedate eq shipdate
             and Order.OrderDate ge dStartDate:
            for each OrderLine no-lock
               where OrderLine.OrderNum eq Order.OrderNum:
                assign salesPipeline.amount = salesPipeline.amount + (OrderLine.Price * OrderLine.Qty).
            end.
        end.
        release salesPipeline.

        create salesPipeline.
        assign salesPipeline.category = "Invoiced".
        for each Order no-lock
           where Order.OrderStatus eq "Shipped"
             and Order.OrderDate ge dStartDate:
            for each Invoice no-lock
               where Invoice.OrderNum eq Order.OrderNum
                 and Invoice.CustNum eq Order.CustNum:
                assign salesPipeline.amount = salesPipeline.amount + (Invoice.Amount).
            end.
        end.
        release salesPipeline.

        create salesPipeline.
        assign salesPipeline.category = "Paid".
        for each Order no-lock
           where Order.OrderStatus eq "Shipped"
             and can-find(first Invoice no-lock
                          where Invoice.OrderNum eq Order.OrderNum
                            and Invoice.CustNum eq Order.CustNum)
             and Order.OrderDate ge dStartDate:
            for each Invoice no-lock
               where Invoice.OrderNum eq Order.OrderNum
                 and Invoice.CustNum eq Order.CustNum:
                assign salesPipeline.amount = salesPipeline.amount + (Invoice.TotalPaid).
            end.
        end.
        release salesPipeline.

        create salesActuals.
        for each Order no-lock
           where Order.OrderStatus eq "Shipped"
             and Order.OrderDate ge dStartDate:
            for each OrderLine no-lock
               where OrderLine.OrderNum eq Order.OrderNum:
                assign salesActuals.yearAmt = salesActuals.yearAmt + (OrderLine.Price * OrderLine.Qty).
            end.
        end.
        assign
            salesActuals.monthAmt = truncate(salesActuals.yearAmt / month(today), 2)
            salesActuals.yearGoal = truncate(salesActuals.yearAmt + (salesActuals.yearAmt * 0.20), 2)
            .
        release salesActuals.
    end method. /* getSalesStats */

    method private void getTopStats ( input piTopStats as integer ):
        define variable ix as integer no-undo.

        empty temp-table ttTopCust.
        empty temp-table ttTopRep.

        for each Order no-lock
           break by Order.CustNum:
            if first-of(Order.CustNum) then do:
                create ttTopCust.
                assign ttTopCust.CustNum = Order.CustNum.

                for each OrderLine no-lock
                   where OrderLine.OrderNum eq Order.OrderNum:
                    assign ttTopCust.SalesAmt = ttTopCust.SalesAmt + (OrderLine.Price * OrderLine.Qty).
                end.
            end.
        end.

        for each Order no-lock
           break by Order.SalesRep:
            if first-of(Order.SalesRep) then do:
                create ttTopRep.
                assign ttTopRep.SalesRep = Order.SalesRep.

                for each OrderLine no-lock
                   where OrderLine.OrderNum eq Order.OrderNum:
                    assign ttTopRep.SalesAmt = ttTopRep.SalesAmt + (OrderLine.Price * OrderLine.Qty).
                end.
            end.
        end.

        for each RefCall no-lock
           break by RefCall.CustNum:
            if first-of(RefCall.CustNum) then do:
                create ttTopCall.
                assign
                    ttTopCall.CustNum  = RefCall.CustNum
                    ttTopCall.NumCalls = ttTopCall.NumCalls + random(100, 1000)
                    .
            end.
        end.

        for each ttTopCust
              by ttTopCust.SalesAmt desc ix = 1 to piTopStats:
            find first Customer no-lock
                 where Customer.CustNum eq ttTopCust.CustNum no-error.
            create topCustomer.
            assign
                topCustomer.fullname = Customer.Name when available(Customer)
                topCustomer.amount   = ttTopCust.SalesAmt
                .
        end.

        for each ttTopRep
              by ttTopRep.SalesAmt desc ix = 1 to piTopStats:
            find first SalesRep no-lock
                 where SalesRep.SalesRep eq ttTopRep.SalesRep no-error.
            create topSalesrep.
            assign
                topSalesrep.fullname = SalesRep.RepName when available(SalesRep)
                topSalesrep.amount   = ttTopRep.SalesAmt
                .
        end.

        for each ttTopCall
              by ttTopCall.NumCalls desc ix = 1 to piTopStats:
            find first Customer no-lock
                 where Customer.CustNum eq ttTopCall.CustNum no-error.
            create topCall.
            assign
                topCall.fullname = Customer.Name when available(Customer)
                topCall.calls    = ttTopCall.NumCalls
                .
        end.
    end method. /* getTopStats */


    /***** Public Methods *****/


    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/statistics", alias="statistics", mediaType="application/json").
    method public void getStats ( input  topStats as integer,
                                  output dataset for dashboardData ):
        if topStats eq ? or
           topStats le 0 or
           topStats gt 10 then
            assign topStats = 10.

        getSalesStats().
        getTopStats(topStats).
    end method. /* getStats */

end class.