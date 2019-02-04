/* *************************************************************************************************************************
Copyright (c) 2018 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
************************************************************************************************************************** */
/*------------------------------------------------------------------------
    File        : FilterParserBuilder
    Purpose     : Contains a registry of objects used to parse JSON or other (typically)
                  string-based filters and create strongly-typed objects
    Description : 
    Author(s)   : pjudge
    Created     : 2018-08-05
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.BusinessLogic.Filter.FilterParser.
using OpenEdge.BusinessLogic.Filter.FilterParserBuilder.
using OpenEdge.BusinessLogic.Filter.FilterParserRegistry.
using OpenEdge.Core.Assert.
using OpenEdge.Core.ISupportInitialize.
using OpenEdge.Core.Util.BuilderRegistry.
using OpenEdge.Core.Util.ConfigBuilder.
using Progress.Json.ObjectModel.JsonObject.

class OpenEdge.BusinessLogic.Filter.FilterParserBuilder inherits ConfigBuilder:
    /* (mandatory) The filter pattern for which we create the Parser */
    define public property FilterPattern as character no-undo
        get.
        private set.
    
    /** Each concrete builder will implement this differently */
    define public property Parser as FilterParser no-undo
        get():
            return BuildParser().
        end get. 
    
    /** Registry for mapping build types to their implementations */
    define static public property Registry as BuilderRegistry no-undo
        get():
            define variable oRegistry as BuilderRegistry no-undo.
            if not valid-object(FilterParserBuilder:Registry) then
            do:
                assign oRegistry = new BuilderRegistry(get-class(FilterParserBuilder)).
                oRegistry:Put(get-class(FilterParserBuilder):TypeName, get-class(FilterParserBuilder)).
                assign FilterParserBuilder:Registry = oRegistry.
            end.
            return FilterParserBuilder:Registry.
        end get.
        private set.
    
    /* Constructor
       
       @param character The filter type that we're constructing a parser for */
    constructor public FilterParserBuilder (input pPattern as character):
        Assert:NotNullOrEmpty(pPattern, 'Filter pattern').
        
        assign this-object:FilterPattern = pPattern.
    end method.
    
    /* Returns a parser builder for a give filter pattern.
       
       @param character The filter pattern name
       @return FilterParserBuilder A builder for a parser for that pattern. */
    method static public FilterParserBuilder Build(input pPattern as character):
        define variable builderType as Progress.Lang.Class no-undo.
        define variable builder as FilterParserBuilder no-undo.
        
        Assert:NotNull(pPattern, 'Filter data').
        
        assign builderType = FilterParserBuilder:Registry:Get(get-class(FilterParserBuilder):TypeName).        
        if valid-object(builderType) then
        do:
            Assert:IsType(builderType, get-class(FilterParserBuilder)).
            
            builder = dynamic-new string(builderType:TypeName)(pPattern).
        end.
        else
            builder = new FilterParserBuilder(pPattern).
        
        if type-of(builder, ISupportInitialize) then
            cast(builder, ISupportInitialize):Initialize().
        
        return builder.
    end method.
    
    /** Returns an argument value writer for a argument type
    
        Specialised JSON filter parsers are used. To figure out which on to 
        use
           1. Look for a parser that matches the name of the first property in the JSON
           2. If none is found, then loop for a property in the JSON that matches one of the
              registered filter parsers.
           3. If no parser is found, return without raising error.
        
        @param  JsonObject The entire filter
        @return FilterParserBuilder The entity writer builder to use */
    method static public FilterParserBuilder Build(input pFilter as JsonObject):
        define variable builder as FilterParserBuilder no-undo.
        define variable keyCnt as integer no-undo.
        define variable keyMax as integer no-undo.
        // AS CHARACTER suffers from ADAS-7500
        define variable propNames as longchar extent no-undo.
        
        Assert:NotNull(pFilter, 'JSON Filter').
        
        assign propNames = pFilter:GetNames()
               keyMax    = extent(propNames)
               .
        // no data
        if extent(propNames) eq ? then
            return builder.
        
        do keyCnt = 1 to keyMax while not valid-object(builder):
            assign builder = FilterParserBuilder:Build(string(propNames[keyCnt])).
        end.
        
        return builder.
    end method.
    
    /* Builds a parser for a JSON filter
       
       @param character The name of the parser to find
       @return FilterParser A usable parser, if one exists. May return NULL */
    method protected FilterParser BuildParser():
        define variable parserType as class Progress.Lang.Class no-undo.
        define variable parser as FilterParser no-undo.
        define variable filterTable as character extent no-undo.
        
        assign parserType = FilterParserRegistry:Registry:Get(this-object:FilterPattern).
        if not valid-object(parserType) then
            return parser.
        
        if HasOption('filterTable':u) then
            assign filterTable = GetOptionStringArrayValue('filterTable':u).
        
        // no option or empty data
        if extent(filterTable) eq ? then
            assign extent(filterTable) = 1
                   filterTable[1]      = '':u
                   .
        parser = dynamic-new string(parserType:TypeName) (filterTable).
        
        if type-of(parser, ISupportInitialize) then
            cast(parser, ISupportInitialize):Initialize().
        
        return parser.
    end method.
    
    /* Sets the table for which this filter applies, if any
       
       @param character A table name for this filter
       @return FilterParserBuilder this object */
    method public FilterParserBuilder TableName(input pTable as character):
        define variable tables as character extent 1 no-undo.
        
        Assert:NotNull(pTable, 'Table name').
        assign tables[1] = pTable.
        
        return TableName(tables).
    end method.

    /* Sets the table for which this filter applies, if any
       
       @param character[] Table names for this filter
       @return FilterParserBuilder this object */
    method public FilterParserBuilder TableName(input pTable as character extent):
        Assert:NotNull(pTable, 'Table name').
        
        SetOption('filterTable':u, pTable).
        
        return this-object.
    end method.
    
end class.