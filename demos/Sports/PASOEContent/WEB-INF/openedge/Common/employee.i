/*------------------------------------------------------------------------
   File        : Employee
   Purpose     :
   Syntax      :
   Description :
   Author(s)   : Code Wizard
   Created     : 07/01/16
   Notes       :
 ----------------------------------------------------------------------*/

@openapi.openedge.entity.primarykey(fields="EmpNum").
@openapi.openedge.entity.field.property(field="id", name="semanticType", value="Internal").
@openapi.openedge.entity.field.property(field="seq", name="semanticType", value="Internal").

define temp-table ttEmployee no-undo before-table bttEmployee
    field id               as character
    field seq              as integer   initial ?
    field EmpNum           as integer   label "Emp No"
    field LastName         as character label "Last Name"
    field FirstName        as character label "First Name"
    field Address          as character label "Address"
    field Address2         as character label "Address2"
    field City             as character label "City"
    field State            as character label "State"
    field PostalCode       as character label "Postal Code"
    field HomePhone        as character label "Home Phone"
    field WorkPhone        as character label "Work Phone"
    field DeptCode         as character label "Dept Code"
    field Position         as character label "Position"
    field Birthdate        as date      label "Birthdate"
    field StartDate        as date      label "Start Date"
    field VacationDaysLeft as integer   label "Vacation Days Left" serialize-name "RemainingPTO"
    field SickDaysLeft     as integer   label "Sick Days Left"
    index pkSeq            is primary unique seq
    index idxDeptCode                 DeptCode
    index idxEmpNo         is unique  EmpNum
    index idxName          is unique  LastName FirstName
    .

define dataset dsEmployee for ttEmployee.
