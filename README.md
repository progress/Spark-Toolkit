# Progress Spark Toolkit

### Welcome!

The **Progress Spark Toolkit** is a [CCS-compliant](https://github.com/progress/CCS) reference implementation from Progress meant to aid in creating an ABL application which provides RESTful API's for microservices. This repository primarily contains ABL artifacts and was built specifically for the **Progress Application Server for OpenEdge** to provide the back-end (server-side) support for exposing ABL logic via HTTP/HTTP.

**Latest Release:** v6.0.0 (October 2020) for OE 11.7.7+ and OE 12.2.2+

## Requirements

Due to the inclusion of the CCS libraries and new Business Logic features within the OpenEdge product, version **11.7.5** or **12.1** is required as a minimum, along with toolkit version **6.0.0** or later being highly recommended. Current builds of the PL files in the following distribution directories are compiled using the following OpenEdge versions for proper compatibility:

* /dist/oe11 - 11.7.5+, 11.7.7+ preferred
* /dist/oe12 - 12.1+, 12.2.2+ preferred

**Previous Release Requirements:**

OE 11.7.5+ or OE 12.1+ for v5.0.x

OE 11.7.4+ or OE 12.0+ for v4.4.0 through 4.6.x

OE 11.7.3+ for v4.3.0 (deprecated, upgrade recommended)

### Supporting Tools

- Apache Ant 1.9.x+ (included with OE 11.7+/12.0+ at DLC/ant) executed as `DLC/bin/proant`
- Progress Compile Tools, aka. "PCT" (included as of OE 11.7.3/12.0+ at DLC/pct/PCT.jar)


## Project Usage

As previously mentioned, the Progress Spark Toolkit library is intended for use with the **Progress Application Server for OpenEdge** (PASOE) as the target for deployment of applications. As such, projects utilizing the framework are expected to be of type "ABL Web App" and deployed to a PAS instance with the exposed Data Services.

1. Copy the `/dist/Spark.pl` library to your project's AppServer directory.
2. Add the procedure library to the PROPATH of your project.
3. At deployment, copy any PL's into the `CATALINA_BASE/openedge` folder of your PAS instance.
4. Add the procedure libraries to the PROPATH of your server instance.
5. Copy the .json and .cp files from the `/cfg/` folder to a new `CATALINA_BASE/conf/spark/` directory.
6. If intending to utilize OERealm security, copy the `/cfg/Realm/SparkRealm.json` file to `CATALINA_BASE/conf/spark/` and `/cfg/Realm/SparkRealm.cp` to `CATALINA_BASE/common/lib/`.

**CCS Note:** As of release **4.6.0** the inclusion of the CCS source code and Ccs.pl has been discontinued and all related source is removed from this repository. As of **OpenEdge 11.7.5 / 12.1** all CCS class interfaces are already included within the product and are utilized to build the Spark.pl library. Therefore, it is no longer necessary to include this PL file within your PROPATH or included as part of your code promotion processes.


## Contributions / Changes

This repository should be ready to use as-is within **Progress Developer Studio for OpenEdge** by importing as an existing project from the `/src/` directory. At this time the contribution model allows fixes from any interested party, subject to accepting the contribution agreement upon check-in of changes. Please see the `CONTRIBUTING.md` file for more information. Pull requests may still be reviewed prior to acceptance.


## Builds / Distribution

To create an updated distribution of the PL libraries, utilize the "ant" program from within the `/src/` directory. Running "ant" without options will display basic usage instructions. For example, to build the `Spark.pl` file you would use the target `build_spark_pl` which requires a variable `version` to be set. The following command would produce a new version of the PL in the `/dist/` folder, reflecting the format of "major.minor.revision":

    ant build_spark_pl -Dversion=Ma.Mi.Rv


## Documentation

Please view the "docs" folder to view various forms of documentation for the available code (ABLDuck and PCTDoc). These formats can be re-generated using the same "ant" script as noted above for builds according to the usage instructions. Supplemental guides and supporting resources may be found in this directory as well.
