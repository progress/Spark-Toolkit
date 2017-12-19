/*------------------------------------------------------------------------
    File        : OERealmDefs
    Purpose     : Hold static attribute names and other definitions for
                : use by the OERealm service (appSecurity-xxxx-oerealm).
    Description :
    Author(s)   :
    Created     :
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.* from propath.

block-level on error undo, throw.

class Spark.Core.Constant.OERealmDefs final:

    /* Misc attributes */
    define public static property REALM_ATTR_LOCKED as character initial "ATTR_LOCKED" no-undo get.

    /* OpenEdge _User table attributes */
    define public static property REALM_ATTR_USERID as character initial "ATTR_USERID" no-undo get.
    define public static property REALM_ATTR_ROLES as character initial "ATTR_ROLES" no-undo get.
    define public static property REALM_ATTR_USERNAME as character initial "ATTR_USERNAME" no-undo get.
    define public static property REALM_ATTR_USERNUMBER as character initial "ATTR_USERNUMBER" no-undo get.
    define public static property REALM_ATTR_GROUPNUMBER as character initial "ATTR_GROUPNUMBER" no-undo get.
    define public static property REALM_ATTR_GIVENNAME as character initial "ATTR_GIVENNAME" no-undo get.
    define public static property REALM_ATTR_MIDDLEINITIAL as character initial "ATTR_MIDDLEINITIAL" no-undo get.
    define public static property REALM_ATTR_SURNAME as character initial "ATTR_SURNAME" no-undo get.
    define public static property REALM_ATTR_TELEPHONE as character initial "ATTR_TELEPHONE" no-undo get.
    define public static property REALM_ATTR_EMAIL as character initial "ATTR_EMAIL" no-undo get.
    define public static property REALM_ATTR_DESCRIPTION as character initial "ATTR_DESCRIPTION" no-undo get.
    define public static property REALM_ATTR_ENABLED as character initial "ATTR_ENABLED" no-undo get.
    define public static property REALM_ATTR_CREATEDATE as character initial "ATTR_CREATEDATE" no-undo get.
    define public static property REALM_ATTR_EXPIRED as character initial "ATTR_EXPIRED" no-undo get.
    define public static property REALM_ATTR_DOMAIN as character initial "ATTR_DOMAIN" no-undo get.

    /* LDAP attributes */
    define public static property REALM_ATTR_CN as character initial "ATTR_CN" no-undo get.
    define public static property REALM_ATTR_SN as character initial "ATTR_SN" no-undo get.
    define public static property REALM_ATTR_UID as character initial "ATTR_UID" no-undo get.
    define public static property REALM_ATTR_TITLE as character initial "ATTR_TITLE" no-undo get.
    define public static property REALM_ATTR_STREET as character initial "ATTR_STREET" no-undo get.
    define public static property REALM_ATTR_POBOX as character initial "ATTR_POBOX" no-undo get.
    define public static property REALM_ATTR_POSTALCODE as character initial "ATTR_POSTALCODE" no-undo get.
    define public static property REALM_ATTR_CITY as character initial "ATTR_CITY" no-undo get.
    define public static property REALM_ATTR_STATE as character initial "ATTR_STATE" no-undo get.
    define public static property REALM_ATTR_DISPLAYNAME as character initial "ATTR_DISPLAYNAME" no-undo get.
    define public static property REALM_ATTR_LANGUAGE as character initial "ATTR_LANGUAGE" no-undo get.
    define public static property REALM_ATTR_EMPLOYEENUM as character initial "ATTR_EMPLOYEENUM" no-undo get.
    define public static property REALM_ATTR_MOBILE as character initial "ATTR_MOBILE" no-undo get.

end class.
