# Progress Spark Toolkit

Welcome! The **Progress Spark Toolkit** is primarily a server-side toolkit to aid in creating an ABL application which provides RESTful API's for microservices. It was build specifically for the **Progress Application Server for OpenEdge** to provide the back-end support for exposing ABL logic via HTTP/HTTPS.


## Requirements

OpenEdge 11.7.3 or later is highly recommended, with the most current release compiled on this version and utilizing several product improvements available. Some features also utilize upcoming code available in the forthcoming 11.7.4 but are provided in a Procedure Library (PL) bundled for easy inclusion in your PROPATH.

**Regression Note:** While the toolkit is *technically* compatible with OE 11.6.3, it must be re-compiled on that version due to changes in ABL library dependencies in OpenEdge. For maximum compatibility and support, use of 11.7 is still preferred if possible.

### Supporting Tools

Apache Ant 1.9.x+ (now included with OE 11.7+ at DLC/ant)

Progress Compile Tools, aka. "PCT" (now included with OE 11.7.3 at DLC/pct/PCT.jar)


## Project Usage

As previously mentioned, the Progress Spark Toolkit library is intended for use with the **Progress Application Server for OpenEdge** (PASOE) as the target for deployment of applications. As such, projects utilizing the framework are expected to be of type "ABL Web App" and deployed to a PAS instance with the exposed Data Services.

**Dependency Note:** Please copy/include the `/dist/OpenEdge.Net.11.7.4.pl` library if not yet using 11.7 SP4.

1. Copy the `/dist/Spark.pl` library to your project's AppServer directory.
2. Add the procedure libraries to the PROPATH of your project.
3. At deployment, copy any PL's into the `CATALINA_BASE/openedge` folder of your PAS instance.
4. Add the procedure libraries to the PROPATH of your server instance.
5. Copy the .json and .cp files from the `/cfg/` folder to a new `CATALINA_BASE/conf/spark/` directory.
6. If intending to utilize OERealm security, copy the `/cfg/Realm/SparkRealm.json` file to `CATALINA_BASE/conf/spark/` and `/cfg/Realm/SparkRealm.cp` to `CATALINA_BASE/common/lib/`.

**CCS Note 1:** If using 11.7.2 or later, the CCS classes are now included in the OpenEdge product. However, the released SP2 build contained a typo which prevented one class from compiling correctly, and has since been fixed in SP3. Therefore, if using OE 11.7.0 through 11.7.2 simply include the `/dist/Ccs.pl` along side the `Spark.pl` mentioned above.

**CCS Note 2:** The product-provided CCS r-code is located in the `DLC/gui/OpenEdge.BusinessLogic.pl` library. Source code is not included within the product-bundled PL file, but does exist within the `/dist/Ccs.pl` bundled within the Spark-Toolkit repository as well as the `/src/Ccs` directory.


## Contributions / Changes

This repository should be ready to use as-is within **Progress Developer Studio for OpenEdge** by importing as an existing project from the `/src/` directory. At this time the contribution model allows fixes from any interested party, subject to accepting the contribution agreement upon check-in of changes. Please see the `CONTRIBUTING.md` file for more information. Pull requests may still be reviewed prior to acceptance.


## Builds / Distribution

To create an updated distribution of the PL libraries, utilize the "ant" program from within the `/src/` directory. Running "ant" without options will display basic usage instructions. For example, to build the `Spark.pl` file you would use the target `build_spark_pl` which requires a variable `version` to be set. The following command would produce a new version of the PL in the `/dist/` folder, reflecting the version "4.3.0":

    ant build_spark_pl -Dversion=4.3.0


## Documentation

Please view the "docs" folder to view various forms of documentation for the available code (ABLDuck and PCTDoc). These formats can be re-generated using the same "ant" script as noted above for builds according to the usage instructions.
