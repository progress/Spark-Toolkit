/*------------------------------------------------------------------------
    File        : Family
    Purpose		:
    Syntax      :
    Description :
    Author(s)   : Dustin Grau
    Created     : Mon Nov 13 14:37:07 EST 2017
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Main Block  *************************** */

/** Dynamically generated schema file **/

@openapi.openedge.entity.primarykey(fields="EmpNum").

define temp-table ttFamily before-table bttFamily
    field EmpNum            as integer   initial "0" label "Emp No"
    field RelativeName      as character label "Relative Name"
    field Relation          as character label "Relation"
    field Birthdate         as date      label "Birthdate"
    field CoveredOnBenefits as logical   initial "no" label "Covered On Benefits"
    field BenefitDate       as date      label "Benefit Date"
    index EmpNoRelativeName is primary unique EmpNum ascending RelativeName ascending
    .

define dataset dsFamily for ttFamily.
