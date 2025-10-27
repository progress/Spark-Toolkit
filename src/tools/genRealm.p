/*------------------------------------------------------------------------
    File        : genRealm.p
    Purpose     : Generate an application-agnostic CP token for Realm use.
    Syntax      : Execute procedure without need for database connection.
    Description :
    Author(s)   : Dustin Grau
    Created     : Mon Nov 14 15:06:27 EST 2016
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

&global-define DLC C:\Progress\OpenEdge
&global-define BaseName SparkRealm
&global-define PassCodeValue SparkRealm01

/* ***************************  Main Block  *************************** */

/* Execute the standard DLC binary to generate the token using only the user/password options. */
os-command silent value(substitute("&1\bin\genspacp -password &2 -user sparkRest -file &3{&BaseName}.cp",
                                   "{&DLC}", "{&PassCodeValue}", session:temp-directory)).

/* Create a CP token for OERealm use based on the given domain information. */
define variable oRealm as Progress.Json.ObjectModel.JsonObject no-undo.
assign oRealm = new Progress.Json.ObjectModel.JsonObject().
oRealm:Add("debug", false).
oRealm:Add("domain", "OESPA").
oRealm:Add("password", security-policy:encode-domain-access-code("{&PassCodeValue}")).
oRealm:Add("role", "SPAClient").
oRealm:WriteFile(substitute("&1{&BaseName}.json", session:temp-directory), true).

/* Alert the user of where to find any files. */
message substitute("See '{&BaseName}' output in '&1'", session:temp-directory) view-as alert-box.

finally:
    delete object oRealm no-error.
end finally.