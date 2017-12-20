THIS IS NOT A PROJECT!

This is a project overlay, meant to get you up and running quickly with the Progress Modernization Framework.
To use, create your ABL Web App project using PDSOE like normal, naming and deploying where you wish, and
accepting the default WebHandler service. Once you have completed the standard project wizard, copy the
contents of this directory over your new project, and delete your default WebHandler class and service.

The resulting project additions will set up a new DataObjectService for you, pointing to the PMFO handler.
You will also be given default implementations of oeablSecurity*.xml files for anonymous, form-local, and
form-oerealm support, using the default "spark" domain and associated passphrase (the same as noted in
the various configuration files of Deploy/Conf, also included).

To immediately create a compatible PAS instance, run "ant" from the command line, while within the AppServer
directory of your newly-created project. This will give sample usage instructions for using the script to
generate a new PAS instance. Adjust the parameters as necessary, and it will be created and tailored for use
with your PMFO project.