# Progress Modernization Framework for OpenEdge

Server-side library to aid in creating an application providing RESTful API's for microservices.


Requirements
====================
OpenEge 11.6.3 or later (11.7.x preferred)

Apache Ant 1.9.x+ (included in OE 11.7)


Assumptions
====================

Use of the Progress Application Server (PAS) is the intended server for deployment of applications utilizing the PMFO library. In other words, projects utilizing the framework are expected to be of type "ABL Web App" and deployed to a PAS instance with exposed Data Services.


Installation / Setup
====================

Include the PMFO.pl from within the "/framework/server/" directory to your project's AppServer directory, and add this procedure library to the PROPATH of your project. At deployment, ensure the .PL file is copied into the CATALINA_BASE/openedge folder of your PAS instance, and likewise added to the PROPATH of your server instance. If using 11.7.1 or earlier, include the Ccs.pl library as well using the same process as stated for the PMFO.pl file. As of 11.7.2 the CCS classes are included automatically within the core OpenEdge language.


Contributions / Changes
====================

This repository should be ready to use as-is, and at present only source may be retrieved (no contribution model or related guidelines have been established as of yet).


Documentation
====================

Please view the "docs" folder to view various forms of documentation for the available code (JavaScript and ABL).
