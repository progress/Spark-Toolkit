# Progress Spark Toolkit

Primarily a server-side tookit to aid in creating an application providing RESTful API's for microservices.


## Requirements

OpenEge 11.7.2 or later (compatible back to 11.6.3)

Apache Ant 1.9.x+ (now included with OE 11.7.0)


## Project Usage

While the Progress Spark Toolkit library *may* be used in **Classic AppServer** situations, use of the **Progress Application Server** (PAS) is the intended server for deployment of applications utilizing the included library. In other words, projects utilizing the framework are expected to be of type "ABL Web App" and deployed to a PAS instance with exposed Data Services.


1. Copy the files `/dist/PMFO.pl` and `/dist/Ccs.pl` to your project's AppServer directory.
2. Add the procedure libraries to the PROPATH of your project.
3. At deployment, copy the PL's into the `CATALINA_BASE/openedge` folder of your PAS instance.
4. Add the procedure libraries to the PROPATH of your server instance.
5. Copy the .json and .cp files from the `/cfg/` folder to a new `CATALINA_BASE/conf/spark/` directory.
6. If intending to utilize OERealm security, copy the `/cfg/Realm/SparkRealm.json` file to `CATALINA_BASE/conf/spark/` and `/cfg/Realm/SparkRealm.cp` to `CATALINA_BASE/common/lib/`.

**Note:** If using 11.7.2 or later, the CCS classes are now included in the OpenEdge product. However, the released SP2 build contained a typo which prevented one Spark class from compiling correctly in PMFO, and has since been fixed in 11.7.3. The provided CCS r-code is located in the DLC/gui/OpenEdge.BusinessLogic.pl library. Note that source code is not included within the product-bundled PL file, but does exist within the Ccs.pl provided within the Spark-Toolkit repository (located in /dist/).


## Contributions / Changes

This repository should be ready to use as-is within **Progress Developer Studio** by importing as an existing project from the `/src/` directory. At this time no contribution model or related guidelines have been established, so pull requests will NOT be honored until proper code review and standards have been put into place.


## Builds / Distribution

To create an updated distribution of the PL libraries, utilize the "ant" program from within the `/src/` directory. Running "ant" without options will display basic usage instructions. For example, to build the `PMFO.pl` file you would use the target `build_pmfo_pl` which requires a variable `version` to be set. The following command would produce a new version of the PL in the `/dist/` folder, reflecting the version "4.2.0":

    ant build_pmfo_pl -Dversion=4.2.0


## Documentation

Please view the "docs" folder to view various forms of documentation for the available code (ABLDuck and PCTDoc). These formats can be re-generated using the same "ant" script as noted above for builds according to the usage instructions.
