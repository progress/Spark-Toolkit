A version of the Sports2000 database meant for use in multi-tenancy situations.

Notes:
    -Ensure database is using Type II storage areas for multi-tenant table
    -Shared data may be in Type I or II storage areas
    -Must have at least 1 data area, 1 index area, and 1 LOB area
    -Ensure every table has a primary index defined (no default indices)
    -Enable multi-tenancy via "proutil <database-name> -C enableMultitenancy"
    -Using OE Mgmt console, Configure tenants first, followed by domains 
    -Use OE Mgmt console to enable multi-tenancy for all tables
