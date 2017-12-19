/*------------------------------------------------------------------------
    File        : config.i
    Purpose     : Declare common table names used in the code.
                  Enable/disable certain system functionality.

    Description :

    Author(s)   : Dustin Grau (dugrau@progress.com)
    Created     : Mon Dec 22 09:12:07 EST 2014
    Notes       :
  ----------------------------------------------------------------------*/

/*** Specific settings for optional features. ***/

/***** Enable basic account authentication. *****/
&GLOBAL-DEFINE USE_BP_ACCOUNT_AUTH FALSE
&GLOBAL-DEFINE WEB_AUDIT_ID_SEQ    WebAuditLogIDSeq
&GLOBAL-DEFINE WEB_USERAUDIT_TABLE WebAuditLog

/***** Enable basic role/task permissions.  *****/
&GLOBAL-DEFINE USE_BP_PERMISSIONS  TRUE
&GLOBAL-DEFINE WEB_PROFILE_TABLE   WebProfile
&GLOBAL-DEFINE WEB_ROLEDATA_TABLE  WebRole
&GLOBAL-DEFINE WEB_ROLEUSER_TABLE  WebRoleProfile
&GLOBAL-DEFINE WEB_ROLETASK_TABLE  WebRoleTask
&GLOBAL-DEFINE WEB_TASKDATA_TABLE  WebTask

/***** Enable basic session management.  *****/
&GLOBAL-DEFINE USE_BP_SESSION_MGMT TRUE
&GLOBAL-DEFINE WEB_CONTEXT_TABLE   WebContext
&GLOBAL-DEFINE WEB_SESSION_TABLE   WebSession
&GLOBAL-DEFINE WEB_ATTRIBUTE_TABLE WebSessionAttribute
&GLOBAL-DEFINE WEB_STATISTIC_TABLE WebSessionStat

/***** Enable use of CLOB table for data.   *****/
&GLOBAL-DEFINE USE_WEB_DATA_STORE  TRUE
&GLOBAL-DEFINE WEB_DATASTORE_TABLE WebDataStore

/***** Enable use of BLOB table for files.  *****/
&GLOBAL-DEFINE USE_WEB_FILE_STORE  TRUE
&GLOBAL-DEFINE WEB_FILESTORE_TABLE WebFileStore

/***** Enable use of system settings.  *****/
&GLOBAL-DEFINE USE_BP_SETTINGS   TRUE
&GLOBAL-DEFINE WEB_SETTING_TABLE WebSetting

/***** Enable use of task-based user menu.  *****/
&GLOBAL-DEFINE USE_WEB_MENU_SYSTEM TRUE
&GLOBAL-DEFINE WEB_MENUDATA_TABLE  WebMenu
&GLOBAL-DEFINE WEB_MENULANG_TABLE  WebMenuTranslate
