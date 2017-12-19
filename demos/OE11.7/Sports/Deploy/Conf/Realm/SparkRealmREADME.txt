To prevent unknown requests from reaching the Hybrid Realm service provider, we must utilize the realmTokenFile
option in the OERealm configuration file. This will provide an identity as context across the AppServer request,
whether internally for a PAS instance or to an external server, marking it as a request from a known source. On
the receiving side it is the duty of the Hybrid Realm class to validate the request and confirm the passed token.

NOTE: It is by design that this CP token does NOT use the same passphrase as any other domain in your application!
This is only meant to secure the requests for authentication, and not for general access to your application data.

To generate a serialized Client Principal file that will be passed from the REST Adapter to the Hybrid Realm service:

1. Use the genspacp utility from the $DLC/bin directory as follows:

genspacp -password sp4rkR3alm -user sparkRest -file SparkRealm.cp

genspacp 1.0
Generated sealed Client Principal...
    User: sparkRest@OESPA
    Id: 6EeGh6ptSrWBp9Ekrp0kRw
    Role: SPAClient
    Encoded Password: oech1::23227b35391760323c3f
    File: SparkRealm.cp
    State: SSO from external authentication system
    Seal is valid

2. Copy the encoded password generated above and update the password in the SparkRealm.json file
Note: Be sure to state the correct domain name (default "OESPA") as well within this config file.

3. Copy the role generated above and update the role in the SparkRealm.json file

4. Copy the SparkRealm.cp to somewhere the REST application can read it from
Note: You would expect this to be the classes directory, i.e. {$CATALINA_BASE}/webapps/<PROJECT>/WEB-INF/classes
      However as of 11.5+ for PAS the intended location is the {$CATALINA_BASE}/common/lib directory

5. Copy the SparkRealm.json file to {$CATALINA_BASE}/conf/spark (or your SPARK_CONF directory).

6. Specify "SparkRealm.cp" file as the "realmTokenFile" attribute value in the oeablSecurity-*-oerealm.xml file.
Note: This is located in the OERealmUserDetails bean.

7. Restart the PAS instance to ensure that the configuration change is picked up.