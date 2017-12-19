/*------------------------------------------------------------------------
   File        : Family
   Purpose     :
   Syntax      :
   Description :
   Author(s)   : Code Wizard
   Created     : 11/27/17
   Notes       :
 ----------------------------------------------------------------------*/

@openapi.openedge.entity.primarykey(fields="EmpNum,RelativeName").
@openapi.openedge.entity.field.property(field="id", name="semanticType", value="Internal").
@openapi.openedge.entity.field.property(field="seq", name="semanticType", value="Internal").

define temp-table ttFamily no-undo before-table bttFamily
    field id                as character
    field seq               as integer   initial ?
    field EmpNum            as integer   label "Emp No" initial 0
    field RelativeName      as character label "Relative Name"
    field Relation          as character label "Relation"
    field Birthdate         as date      label "Birthdate"
    field CoveredOnBenefits as logical   label "Covered On Benefits" initial false
    field BenefitDate       as date      label "Benefit Date"
    index pkSeq is primary unique        seq
    index idxEmpNoRelativeName is unique EmpNum RelativeName
    .

define dataset dsFamily for ttFamily.
