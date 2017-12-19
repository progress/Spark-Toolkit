To ease the initial setup of domain-based security, run the createDomain.p as a Progress
OpenEdge Application connected to your application databases. This will create a "spark"
domain by default (with a passcode of "spark01"). It should also create your CP token to
be used as a "reset" of identity within your PAS agent's sessions, and session.json file
to be used to validate the seal on any CP tokens that are passed within the PAS session.
These files should be placed in the CATALINA_BASE/conf/spark folder, and would supersede
whatever came from the <project>/Deploy/Conf folder.

You may override the domain and passcode values by just changing the pre-processor options
within the file. The goal is to have a simple script which can be moved to any other system
where you will deploy your code, and update the necessary databases.

When working with OERealm security, the script genRealm.p will generate a special CP token
that utilizes a different passcode than any of your application domains. This encoded key
will also be used in the resulting SparkRealm.json file which will be used by the OERealm
endpoint class to validate the seal of the passed CP token. Please note that the token file
SparkRealm.cp must be placed in the CATALINA_BASE/common/lib folder for Tomcat to see it.
For the OERealm class, the SparkRealm.json file must be in CATALINA_BASE/conf or
CATALINA_BASE/conf/spark to be used properly.


/******************************************************************************************/

The following files are needed by the ANT scripts to start/stop/clean/trim the PAS instance:
    manageInstance.p
    clean.bat
    trimAgents.p

Be sure to confirm your hostname and port options within these files, or otherwise call the
programs with parameters as noted within the comments.