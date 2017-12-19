PAS Deployment Script

Requirements:
    ANT 1.9+
    JDK 1.7+

Environment:
    DLC - Set to your OpenEdge installation directory
    JAVA_HOME - Set to your local JDK installation
    ANT_HOME - Set to the location of your ANT folder

Usage:
    Run "ant" to view sample usage and all default values for properties.
    Run "ant create" and override options as necessary to create a new PAS instance.

By default, the script will create a new PAS instance called "MyPAS1" in a directory C:\PASOE
For each PAS instance you intend to create, a directory must be present in the same directory
as the build.xml file, matching the name of the "alias" property specified in the usage notes.

Directory Structure:
    <pas_alias>/
        common/lib - Should contain the SparkRealm.cp if utilizing OERealm security
        conf/spark - Should contain all configuration JSON files, and SparkReset.cp
        openedge - Should contain CCS.pl and PMFO.pl libraries, with any .pf files

The ANT script will create the new PAS instance, and then copy the files from the noted folders
to their respective location within the new instance. The script will then merge a common set of
properties to the instance's openedge.properties file (specified in merge.openedge.properties in
the subdirectory named like the PAS instance). A default WebApp will be deployed to the instance
from DLC/servers/pasoe/extra/oeabl.war and named "app" by default (unless overriden).
