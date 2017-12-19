# Progress Modernization Framework for OpenEdge

Server-side libraries for OpenEdge to aid in creating RESTful API's for microservices.


Requirements
====================
OpenEge 11.6.3 or later (11.7.x preferred)

Apache Ant 1.9.x+ (included in OE 11.7)


Assumptions
====================

Use of the Progress Application Server (PAS) is the intended server for deployment of applications utilizing the PMFO library.


Installation / Setup
====================

Include the PMFO.pl from within the "framework/server/" directory to your project's AppServer directory, and add this procedure library to the PROPATH of your project. At deployment, ensure the .PL file is copied to the CATALINA_BASE/openedge folder of your PAS instance, and likewise added to the PROPATH of your server instance.


Contributions / Changes
====================

This repository should be ready to use as-is, and at present only source may be retrieved (no contribution model established as of yet).


Documentation
====================

Please view the "docs" folder to view various forms of documentation for the available code (JavaScript and ABL).
