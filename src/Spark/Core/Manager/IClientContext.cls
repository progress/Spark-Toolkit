interface Spark.Core.Manager.IClientContext inherits Ccs.Common.IClientContext:

    define public property userDomain as character no-undo get.
    define public property userID as character no-undo get.
    define public property userExtra as character no-undo get.
    define public property loginExpiration as datetime-tz no-undo get.
    define public property activityPassword as character no-undo get.

    method public logical hasUserProperty( input pcProperty as character ).

    method public character extent getUserProperties( ).
    method public character extent getUserPropertyArray( input pcProperties as character extent ).
    method public void getUserPropertyArray( output pcPropNames as character extent, output pcPropValues as character extent ).

    method public character extent getUserArrayPropertyAsChar( input pcProperty as character ).
    method public decimal extent getUserArrayPropertyAsDec( input pcProperty as character ).
    method public integer extent getUserArrayPropertyAsInt( input pcProperty as character ).

    method public character getUserProperty( input pcProperty as character ).
    method public character getUserPropertyAsChar( input pcProperty as character ).
    method public longchar getUserPropertyAsLongchar( input pcProperty as character ).
    method public integer getUserPropertyAsInt( input pcProperty as character ).
    method public int64 getUserPropertyAsInt64( input pcProperty as character ).
    method public decimal getUserPropertyAsDec( input pcProperty as character ).
    method public logical getUserPropertyAsLog( input pcProperty as character ).
    method public date getUserPropertyAsDate( input pcProperty as character ).
    method public datetime getUserPropertyAsDatetime( input pcProperty as character ).
    method public datetime-tz getUserPropertyAsDatetimeTz( input pcProperty as character ).

    method public void setUserProperty( input pcProperty as character, input pcValue as character ).
    method public void setUserProperty( input pcProperty as character, input plcValue as longchar ).
    method public void setUserProperty( input pcProperty as character, input piValue as integer ).
    method public void setUserProperty( input pcProperty as character, input piValue as int64 ).
    method public void setUserProperty( input pcProperty as character, input pdValue as decimal ).
    method public void setUserProperty( input pcProperty as character, input plValue as logical ).
    method public void setUserProperty( input pcProperty as character, input pcValue as date ).
    method public void setUserProperty( input pcProperty as character, input pcValue as datetime ).
    method public void setUserProperty( input pcProperty as character, input pcValue as datetime-tz ).

    method public void setUserProperty( input pcProperty as character, input pcValue as character extent ).
    method public void setUserProperty( input pcProperty as character, input pdValue as decimal extent ).
    method public void setUserProperty( input pcProperty as character, input piValue as integer extent ).

    method public void removeUserProperty( input pcProperty as character ).

    method public void initializeUserProperty( input pcProperty as char  ).

    method public void invalidateContext( ).

    method public void setActivityPassword( input pcActivityPassword as character).

end interface.
