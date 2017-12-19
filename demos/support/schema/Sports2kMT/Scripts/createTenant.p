/*------------------------------------------------------------------------------
  Purpose: Create tenant
  Created: Mon Jun 18 14:04:40 2012 by dataadmin code writer.
    Notes: 
------------------------------------------------------------------------------*/

routine-level on error undo, throw.
using Progress.Lang.Error from propath.
using OpenEdge.DataAdmin.DataAdminService from propath.
using OpenEdge.DataAdmin.Error.DataAdminErrorHandler from propath.
using OpenEdge.DataAdmin.ITenant from propath.
using OpenEdge.DataAdmin.IDomain from propath.
using OpenEdge.DataAdmin.IUser from propath.
using OpenEdge.DataAdmin.IPartition from propath.
using OpenEdge.DataAdmin.ITenantGroupMember from propath.

define input parameter pcTenantName  as character no-undo.
define input parameter pcTenantDescr as character no-undo.
define input parameter pcTenantType  as character no-undo.

define variable databaseName as character no-undo initial "Sports2kMT".

define variable service as DataAdminService no-undo.
define variable errorHandler as DataAdminErrorHandler no-undo.
define variable tenant as ITenant no-undo.
define variable domain as IDomain no-undo.
/* Default domain AccessCode   */
define variable cAccessCode as character init "accesscode" no-undo.
define variable myUser as IUser no-undo.
/* Default user password - can only be changed by the user after creation */
define variable cPassword as character init "password" no-undo.
define variable partition as IPartition no-undo.
define variable tenantGroupMember as ITenantGroupMember no-undo.

/* Start a service for the "Sports2kMT" database. */
service = new DataAdminService(databaseName).

/* Instantiate a new ITenant */
if pcTenantType eq "Super" then do:
    tenant = service:NewTenant(pcTenantName).
    assign
        tenant:ExternalId = ""
        tenant:Type = "Super"
        tenant:Description = pcTenantDescr
        tenant:IsDataEnabled = yes
        .
end.
else do:
    tenant = service:NewTenant(pcTenantName).
    assign
        tenant:ExternalId = ""
        tenant:Type = "Regular"
        tenant:Description = pcTenantDescr
        tenant:IsDataEnabled = yes
        tenant:DefaultDataArea = service:GetArea("Data Area")
        tenant:DefaultIndexArea = service:GetArea("Index Area")
        tenant:DefaultLobArea = service:GetArea("LOB Area")
        tenant:DefaultAllocation = "Immediate"
        .
end.

/* Create (commit) the tenant in the service */
service:CreateTenant(tenant).

message "Tenant Created!" view-as alert-box.

catch e as Error:
    errorHandler = new DataAdminErrorHandler().
    errorHandler:Error(e).
end catch.
