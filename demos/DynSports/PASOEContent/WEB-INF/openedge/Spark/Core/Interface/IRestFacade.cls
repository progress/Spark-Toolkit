/*------------------------------------------------------------------------
    File        : IRestFacade
    Purpose     :
    Description : Generic CRUD Interface for REST
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Fri Dec 12 08:34:00 EST 2014
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.

interface Spark.Core.Interface.IRestFacade:

    /* Provide access via CRUD operations. */
    method public void getCatalog ( input  pcServiceURI   as character,
                                    input  pcResourceName as character,
                                    output pfElapsedTime  as decimal,
                                    output piResponseCode as integer,
                                    output pcJsonResponse as longchar ).

    method public void getCatalogAll ( output pfElapsedTime  as decimal,
                                       output piResponseCode as integer,
                                       output pcJsonResponse as longchar ).

    method public void doCreate ( input  pcResourceName as character,
                                  input  pcMethodName   as character,
                                  input  pcServiceObj   as character,
                                  input  pcJsonParams   as longchar,
                                  output plResult       as logical,
                                  output pfElapsedTime  as decimal,
                                  output piResponseCode as integer,
                                  output pcJsonResponse as longchar ).

    method public void doRead ( input  pcResourceName as character,
                                input  pcMethodName   as character,
                                input  pcServiceObj   as character,
                                input  pcJsonRequest  as longchar,
                                output plResult       as logical,
                                output pfElapsedTime  as decimal,
                                output piResponseCode as integer,
                                output pcJsonResponse as longchar ).

    method public void doUpdate ( input  pcResourceName as character,
                                  input  pcMethodName   as character,
                                  input  pcServiceObj   as character,
                                  input  pcJsonRequest  as longchar,
                                  output plResult       as logical,
                                  output pfElapsedTime  as decimal,
                                  output piResponseCode as integer,
                                  output pcJsonResponse as longchar ).

    method public void doDestroy ( input  pcResourceName as character,
                                   input  pcMethodName   as character,
                                   input  pcServiceObj   as character,
                                   input  pcJsonRequest  as longchar,
                                   output plResult       as logical,
                                   output pfElapsedTime  as decimal,
                                   output piResponseCode as integer,
                                   output pcJsonResponse as longchar ).

    /* Provide access via standard verbs. */

    method public void doGet ( input  pcResourceName as character,
                               input  pcMethodName   as character,
                               input  pcServiceObj   as character,
                               input  pcJsonParams   as longchar,
                               output plResult       as logical,
                               output pfElapsedTime  as decimal,
                               output piResponseCode as integer,
                               output pcJsonResponse as longchar ).

    method public void doPut ( input  pcResourceName as character,
                               input  pcMethodName   as character,
                               input  pcServiceObj   as character,
                               input  pcJsonRequest  as longchar,
                               output plResult       as logical,
                               output pfElapsedTime  as decimal,
                               output piResponseCode as integer,
                               output pcJsonResponse as longchar ).

    method public void doPost ( input  pcResourceName as character,
                                input  pcMethodName   as character,
                                input  pcServiceObj   as character,
                                input  pcJsonRequest  as longchar,
                                output plResult       as logical,
                                output pfElapsedTime  as decimal,
                                output piResponseCode as integer,
                                output pcJsonResponse as longchar ).

    method public void doDelete ( input  pcResourceName as character,
                                  input  pcMethodName   as character,
                                  input  pcServiceObj   as character,
                                  input  pcJsonRequest  as longchar,
                                  output plResult       as logical,
                                  output pfElapsedTime  as decimal,
                                  output piResponseCode as integer,
                                  output pcJsonResponse as longchar ).

    method public void logoutUser ( output pfElapsedTime  as decimal,
                                    output piResponseCode as integer,
                                    output plResult       as logical,
                                    output pcMessage      as character ).

end interface.