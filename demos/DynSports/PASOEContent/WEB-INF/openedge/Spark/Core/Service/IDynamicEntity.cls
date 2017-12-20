/*------------------------------------------------------------------------
    File        : IDynamicEntity
    Purpose     :
    Description :
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Tue Mar 17 09:29:59 EDT 2015
    Notes       :
  ----------------------------------------------------------------------*/

interface Spark.Core.Service.IDynamicEntity inherits Ccs.Common.IService:

    define public property serviceURI   as character no-undo get.
    define public property resourceName as character no-undo get.
    define public property entityName   as character no-undo get.
    define public property primaryKeys  as character no-undo get.
    define public property foreignKeys  as character no-undo get.
    define public property mappingType  as character no-undo get.
    define public property capabilities as character no-undo get.
    define public property operations   as character no-undo get.

    method public void getDataset (output dataset-handle phDataset).

    method public void postRowFill ( input dataset-handle phDataset ).

    method public void readData ( input  filter  as character,
                                  output numRecs as int64,
                                  output dataset-handle phDataSet ).

    method public void createData ( input-output dataset-handle phDataSet ).

    method public void updateData ( input-output dataset-handle phDataSet ).

    method public void deleteData ( input-output dataset-handle phDataSet ).

    method public void submitData ( input-output dataset-handle phDataSet ).

end interface.