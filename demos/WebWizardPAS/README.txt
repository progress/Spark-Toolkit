This project is intended to be deployed directly to your PAS instance without prior compilation.

1) Perform a deployment of the included WebWizard.war file to your PAS instance using "tcman deploy".
2) Modify the CATALINA_BASE/webapps/WebWizard/config/wizard.json file to match the necessary paths
   accordingly for where you intend to deposit any generated content.
    2a) You should only need to modify the section labeled "General".
    2b) The items with "Output" in the name are your primary concern.
    2c) Tailor any other items in this section as necessary.
3) Start (or re-start) your PAS instance to pick up the new application.