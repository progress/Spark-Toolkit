/*------------------------------------------------------------------------
    File        : ISchemaManager
    Purpose     :
    Description : Schema Manager (Interface)
    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Tue Mar 03 13:55:33 EST 2015
    Notes       :
  ----------------------------------------------------------------------*/

interface Spark.Core.Manager.ISchemaManager inherits Ccs.Common.IManager:

    method public void initSchema ( ).

    method public void initMethodSignature ( input poMethodSignature as Spark.Core.Util.MethodSignature ).

    method public void deleteObjects ( ).

    method public void dumpObjects ( ).

    method public void getObject ( input  pcParentName    as character,
                                   input  pcObjectName    as character,
                                   output pcObjectAltName as character,
                                   output pcObjectType    as character,
                                   output pcObjectSchema  as longchar ).

    method public void getObjectChildren ( input  pcParentName as character,
                                           output pcObjectList as character ).

    method public void getObjectList ( input  pcSchemaType as character,
                                       output pcSchemaList as character ).

    method public logical getDataset ( input  pcDatasetName as character,
                                       output dataset-handle phDatasetHandle ).

    method public logical getDataset ( input  plcDatasetSchema as longchar,
                                       output dataset-handle phDatasetHandle ).

    method public logical getTempTable ( input  pcTableName as character,
                                         output table-handle phTableHandle ).

    method public void registerDataset ( input phDatasetHandle as handle ).

    method public void registerTempTable ( input phTableHandle as handle ).


    method public void registerTempTable ( input pcParentObject as character,
                                           input phTableHandle  as handle ).

end interface.