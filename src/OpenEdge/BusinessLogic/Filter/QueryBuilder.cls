/* *************************************************************************************************************************
Copyright (c) 2018 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
************************************************************************************************************************** */
/*------------------------------------------------------------------------
    File        : QueryBuilder
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : pjudge
    Created     : Thu May 10 12:38:00 EDT 2018
    Notes       : ADAS-101
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using Ccs.BusinessLogic.IGetDataRequest.

class OpenEdge.BusinessLogic.Filter.QueryBuilder: 
    
    method public character Build(input pFilter as IGetDataRequest,
                                  input pSchema as handle):
        define variable queryString as character no-undo.
        
        queryString = "WHERE TRUE".
        
        return queryString.
    end method.
    
end class.