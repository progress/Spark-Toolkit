The SessionManager looks for a configuration file "session.json" located in the expected application config file directory.

When the system starts up and at the end of each service request, a default user is asserted against the connected database(s)
This user would typically have a low level of security, but utilizing a domain present in all of the connected databases.
The "ResetClientPrincipal" parameter in the config points to a serialized Client Principal object that defines this "Reset User".

1. To Generate a serialized Client Principal file, use the genspacp utility in $DLC/bin

proenv>genspacp -password spark01 -user sparkRest -role NoAccess -domain spark -file SparkReset.cp
genspacp 1.1
Generated sealed Client Principal...
    User: sparkRest@spark
    Id: cltI3rp3TkW1HxWvTM+XHA
    Role: NoAccess
    File: SparkReset.cp
    State: SSO from external authentication system
    Seal is valid

2. This C-P will be asserted against all connected application databases, so the values you use for the user,
domain, and password must match the domain(s) created in the database, with the CP name noted in session.json.
Note: the -password parameter above is NOT the users password, this is the Domain Access Code.

3. Copy the serialized Client Principal file to the standard config location, where your other configs reside.

4. For the "session.json" file use the genpassword utility to generate the domain passcode using the "odeb0" prefix.

proenv>genpassword -prefix odeb0 -password spark01
odeb0::aqb/3jhBtLDaqwvy0c1440wXieKSyGTFg8QLu6hn4ZWuzD5shUpT24ti1BsfM4up

5. Supply the generated passcode into the "accessCode" property, escaping any forward slashes as necessary.

