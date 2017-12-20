The following changes have been made to files that may not be normally modified for projects:


WEB-INF/spring/authFilters.xml - Optionally adjust the entry point for logins (value property).

    <b:bean id="OEFormEntryPoint"
            class="com.progress.appserv.services.security.OEFormAuthnEntryPointHandler">
            <b:constructor-arg value="/static/login.html" />


WEB-INF/spring/authManagers.xml - Provide a missing property substitution for createCPAuthn.

    <b:property name="createCPAuthn" value="true" />
	or
    <b:property name="createCPAuthn" value="${OERealm.AuthProvider.createCPAuthn}" />


WEB-INF/oeablSecurity.properties - Ensure the following properties exist (for single-tenancy).

    OERealm.AuthProvider.createCPAuthn=true
    OERealm.AuthProvider.sealClientPrincipal=true
    OERealm.AuthProvider.multiTenant=false
    OERealm.AuthProvider.userDomain=
    OERealm.AuthProvider.key=
    OERealm.AuthProvider.authz=true
