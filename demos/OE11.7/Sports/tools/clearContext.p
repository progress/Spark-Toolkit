/*------------------------------------------------------------------------
    File        : clearContext.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Thu Aug 04 11:48:25 EDT 2016
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

/* ***************************  Main Block  *************************** */

for each WebSession:
    delete WebSession.
end.

for each WebSessionAttribute:
    delete WebSessionAttribute.
end.

for each WebDataStore:
    delete WebDataStore.
end.
