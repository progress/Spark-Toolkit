# Progress Spark Toolkit

### Welcome!

The **Progress Spark Toolkit** is a [CCS-compliant](https://github.com/progress/CCS) reference implementation from Progress meant to aid in creating an ABL application which provides RESTful API's for microservices. This repository primarily contains ABL artifacts and was built specifically for the **Progress Application Server for OpenEdge** to provide the back-end (server-side) support for exposing ABL logic via HTTP/HTTP.

**Latest Release:** v4.5.0 (March 2019) for OE 11.7.4+ and initial release for OE 12.0


## Requirements

**OpenEdge 11.7.4** or later is required, with the current toolkit release being compiled on version 11.7.4 and utilizing several product improvements available. Some new features appearing in the 4.4.0 release may still be used with 11.7.3 but may first require a recompile and build of a new PL file. For OpenEdge 12 release 4.5.0 is required (first appearance of pre-compiled oe12 PL files).


### Supporting Tools

- Apache Ant 1.9.x+ (now included with OE 11.7+ at DLC/ant)
- Progress Compile Tools, aka. "PCT" (now included with OE 11.7.3 at DLC/pct/PCT.jar)


## Project Usage

As previously mentioned, the Progress Spark Toolkit library is intended for use with the **Progress Application Server for OpenEdge** (PASOE) as the target for deployment of applications. As such, projects utilizing the framework are expected to be of type "ABL Web App" and deployed to a PAS instance with the exposed Data Services.

1. Copy the `/dist/Spark.pl` library to your project's AppServer directory.
2. Add the procedure library to the PROPATH of your project.
3. At deployment, copy any PL's into the `CATALINA_BASE/openedge` folder of your PAS instance.
4. Add the procedure libraries to the PROPATH of your server instance.
5. Copy the .json and .cp files from the `/cfg/` folder to a new `CATALINA_BASE/conf/spark/` directory.
6. If intending to utilize OERealm security, copy the `/cfg/Realm/SparkRealm.json` file to `CATALINA_BASE/conf/spark/` and `/cfg/Realm/SparkRealm.cp` to `CATALINA_BASE/common/lib/`.

**CCS Note 1:** If using 11.7.0-11.7.2 you will need to include the `/dist/Ccs.pl` along side the `Spark.pl` mentioned above. This is due to a minor typo in 11.7.2's initial inclusion of the CCS classes, which prevented one toolkit class from compiling correctly. This has since been corrected as of the SP3 release.

**CCS Note 2:** The product-provided CCS r-code is located in the `DLC/gui/OpenEdge.BusinessLogic.pl` library. Source code is not included within the product-bundled PL file, but does exist within Spark-Toolkit repository in the `/src/Ccs` directory.


## Contributions / Changes

This repository should be ready to use as-is within **Progress Developer Studio for OpenEdge** by importing as an existing project from the `/src/` directory. At this time the contribution model allows fixes from any interested party, subject to accepting the contribution agreement upon check-in of changes. Please see the `CONTRIBUTING.md` file for more information. Pull requests may still be reviewed prior to acceptance.


## Builds / Distribution

To create an updated distribution of the PL libraries, utilize the "ant" program from within the `/src/` directory. Running "ant" without options will display basic usage instructions. For example, to build the `Spark.pl` file you would use the target `build_spark_pl` which requires a variable `version` to be set. The following command would produce a new version of the PL in the `/dist/` folder, reflecting the format of "major.minor.revision":

    ant build_spark_pl -Dversion=Ma.Ma.Rv


## Documentation

Please view the "docs" folder to view various forms of documentation for the available code (ABLDuck and PCTDoc). These formats can be re-generated using the same "ant" script as noted above for builds according to the usage instructions. Supplemental guides and supporting resources may be found in this directory as well.
