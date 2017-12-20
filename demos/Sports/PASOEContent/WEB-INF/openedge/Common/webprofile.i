/*------------------------------------------------------------------------
   File        : WebProfile
   Purpose     :
   Syntax      :
   Description :
   Author(s)   : Code Wizard
   Created     : 05/09/17
   Notes       :
 ----------------------------------------------------------------------*/

@openapi.openedge.entity.primarykey(fields="Username,DomainName").
@openapi.openedge.entity.field.property(field="id", name="semanticType", value="Internal").
@openapi.openedge.entity.field.property(field="seq", name="semanticType", value="Internal").
@openapi.openedge.entity.field.property(field="HomePhone", name="semanticType", value="PhoneNumber").
@openapi.openedge.entity.field.property(field="WorkPhone", name="semanticType", value="PhoneNumber").

define temp-table ttWebProfile no-undo before-table bttWebProfile
    field id               as character
    field seq              as integer   initial ?
    field UserNum          as integer   label "UserNum"
    field Username         as character label "Username"
    field DomainName       as character label "Domain"
    field Password         as character label "Password"
    field ResetCode        as character label "Reset Code"
    field FirstName        as character label "First Name"
    field LastName         as character label "Last Name"
    field IsActive         as logical   label "Is Active"
    field IsLocked         as logical   label "Is Locked"
    field UseTFA           as logical   label "Use TFA"
    field TFAMethod        as character label "TFA Method"
    field TFAToken         as character label "TFA Token"
    field TFASecret        as character label "TFA Secret"
    field Email            as character label "Email"
    field CompanyName      as character label "Company"
    field JobTitle         as character label "Title"
    field HomePhone        as character label "Home Phone"
    field WorkPhone        as character label "Work Phone"
    field MobilePhone      as character label "Mobile Phone"
    field MobileCarrier    as character label "Mobile Carrier"
    field SecurityQuestion as character label "Security Question"
    field SecurityAnswer   as character label "Security Answer"
    field PasswordExpires  as date      label "Expires"
/*    field OldPassword      as character label "Old Password"*/
    field ForcePWChange    as logical   label "Must Change Password"
    field LockOutDate      as date      label "Lockout Date"
    field LockOutTime      as integer   label "LockOut Time"
/*    field SecurityRole     as character label "Security Role"*/
    field TaskAdjust       as character label "Task Adjustment"
    field Comments         as character label "Comments"
    field FirstLogin       as date      label "First Time Login"
    field LastLogin        as date      label "Last Login"
    field LoginCount       as integer   label "Login Count"
    field ProfileRoles     as character label "Roles"
    index pkSeq            is primary unique   seq
    index idxpkDomainUser  is unique  Username DomainName
    index idxEmail         is unique  Email    DomainName
    index idxNum           is unique  UserNum
    index idxName                     LastName FirstName
    .

define dataset dsWebProfile for ttWebProfile.
