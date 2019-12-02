# Framework Upgrade Process


## Prior to 2.3.0:
- A direct migration path is not available for releases prior to 2.3.0 (deprecated as of February 2017).
- Please consider starting a new ABL Web App project with the latest version of the framework,
 and copying your business logic to the appropriate location under PASOEContent/WEB-INF/openedge

## 2.3.0 to 3.0.0:
- Remove any existing /Spark/ folder from your project's PASOEContent/WEB-INF/openedge directory.
- Copy Ccs.pl and PMFO.pl files from /framework/server/ to your project's /AppServer/ directory.
- Adjust project PROPATH to include these procedure libraries (respectively) as the last entries.
- Deploy Ccs.pl and PMFO.pl files from /framework/server/ to your CATALINA_BASE/openedge directory.
- Adjust instance PROPATH to include these procedure libraries (respectively) as the last entries.
- Copy /framework/client/spark to your project's /PASOEContent/static/vendor/ directory.
- Compare the config files from /framework/server/samples/Conf to your project's /Deploy/Conf/ directory.
- Modify your business logic according to the guide at /framework/server/Spark/UPGRADE_CCS.txt

## 3.0.0 to 3.0.1:
- Copy Ccs.pl and PMFO.pl files from /framework/server/ to your project's /AppServer/ directory.
- Deploy Ccs.pl and PMFO.pl files from /framework/server/ to your CATALINA_BASE/openedge directory.
- Copy /framework/client/spark to your project's /PASOEContent/static/vendor/ directory.

## 3.0.1 to 3.1.0:
- Copy Ccs.pl and PMFO.pl files from /framework/server/ to your project's /AppServer/ directory.
- Deploy Ccs.pl and PMFO.pl files from /framework/server/ to your CATALINA_BASE/openedge directory.
- Copy /framework/client/spark to your project's /PASOEContent/static/vendor/ directory.

## 3.1.0 to 4.0.0:
- Use of this release REQUIRES that you be on OpenEdge 11.7, as security files have changed!
- Migrate your existing ABL Web App projects have been upgraded by PDS to change security files.
- Perform an "SVN Switch" to the new release, which will add/remove files as necessary.
- Copy Ccs.pl and PMFO.pl files from /framework/server/ to your project's /AppServer/ directory.
- Deploy Ccs.pl and PMFO.pl files from /framework/server/ to your CATALINA_BASE/openedge directory.
- Copy /framework/client/spark to your project's /PASOEContent/static/vendor/ directory.

## 3.1.x to 3.2.x or 4.0.x to 4.1.x:
- Perform an "SVN Switch" to the new release, which will add/remove files as necessary.
- Copy Ccs.pl and PMFO.pl files from /framework/server/ to your project's /AppServer/ directory.
- Deploy Ccs.pl and PMFO.pl files from /framework/server/ to your CATALINA_BASE/openedge directory.
- Copy /framework/client/spark to your project's /PASOEContent/static/vendor/ directory.
- Add a property "foreignKey" as character to each BE that utilizes DynamicEntity.
- Note: Login process is updated to utilize new AuthenticationProvider in JSDO.
- Note: The bindAll() method is deprecated in favor of new init() method.

## 4.1 to later releases
- See the "Spark Migration Guide" document for more detailed information.
