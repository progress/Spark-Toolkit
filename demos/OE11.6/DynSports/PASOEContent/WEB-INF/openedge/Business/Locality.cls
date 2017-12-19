/*------------------------------------------------------------------------
    File        : Locality
    Purpose     : Simple class for locality data
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Tue Jun 02 09:51:10 EDT 2015
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.
using OpenEdge.Core.Collections.* from propath.
using Spark.Core.Manager.ISchemaManager from propath.
using Spark.Core.Util.ApplicationError from propath.

block-level on error undo, throw.

{Common/config.i}

class Business.Locality inherits Spark.Core.Service.DynamicResource:

    {Common/state.i}

    define public override property serviceURI as character
        initial "/web/pdo/common" no-undo get.
        protected set.

    define public override property resourceName as character
        initial "locality" no-undo get.
        protected set.

    method public override void initialize ( ):
        /* Describe any properties about invoke methods to be exposed. */
        cast(Ccs.Common.Application:StartupManager:getManager(get-class(ISchemaManager)), ISchemaManager):registerTempTable(input temp-table states:handle).
        Spark.Core.Util.Annotate:describeInvoke(serviceURI, getClassName(), "getStateProvince", "stateProvince", "put").
        Spark.Core.Util.Annotate:describeInvoke(serviceURI, getClassName(), "getProvinces", "provinces", "get").
        Spark.Core.Util.Annotate:describeInvoke(serviceURI, getClassName(), "getStates", "states", "get").
    end method. /* initialize */


    method public void getStateProvince ( input  country as character,
                                          output table for states ):
        case country:
            when "can" or
            when "canada" then
                getProvinces(output table states by-reference).
            when "us" or
            when "usa" then
                getStates(output table states by-reference).
        end case.
    end method. /* getStateProvince */


    method public void getProvinces ( output table for states ):
        define variable oMap  as StringStringMap no-undo.
        define variable oIter as IIterator       no-undo.
        define variable oPair as IMapEntry       no-undo.

        define buffer bState for state.

        empty temp-table states.

        assign oMap = new StringStringMap().

        oMap:Put("AB", "Alberta").
        oMap:Put("BC", "British Columbia").
        oMap:Put("MB", "Manitoba").
        oMap:Put("NB", "New Brunswick").
        oMap:Put("NL", "Newfoundland").
        oMap:Put("NS", "Nova Scotia").
        oMap:Put("NT", "Northwest Territories").
        oMap:Put("NU", "Nunavut").
        oMap:Put("ON", "Ontario").
        oMap:Put("PE", "Prince Edward Island").
        oMap:Put("QC", "Quebec").
        oMap:Put("SK", "Saskatchewan").
        oMap:Put("YT", "Yukon").

        assign oIter = oMap:EntrySet:Iterator().
        do while oIter:HasNext():
            oPair = cast(oIter:Next(), IMapEntry).
            create states.
            assign
                states.Abbrev   = string(oPair:key)
                states.FullName = string(oPair:value)
                .
        end.
    end method. /* getProvinces */


    method public void getStates ( output table for states ):
        define buffer bState for state.

        empty temp-table states.

        for each bState no-lock:
            create states.
            assign
                states.Abbrev   = bState.State
                states.FullName = bState.StateName
                .
        end. /* for each */
    end method. /* getStates */

end class.