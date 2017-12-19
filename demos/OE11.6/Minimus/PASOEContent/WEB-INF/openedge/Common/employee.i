/*------------------------------------------------------------------------
   File        : Employee
   Purpose     :
   Syntax      :
   Description :
   Author(s)   : Code Wizard
   Created     : 11/09/17
   Notes       :
 ----------------------------------------------------------------------*/

/* ***************************  Main Block  *************************** */

/* Dynamically generated schema file */

@openapi.openedge.entity.primarykey(fields="EmpNum").

DEFINE TEMP-TABLE ttEmployee BEFORE-TABLE bttEmployee
    FIELD id AS CHARACTER
    FIELD seq AS INTEGER INITIAL ?
    FIELD EmpNum AS INTEGER LABEL "Emp_No"
    FIELD LastName AS CHARACTER LABEL "Last_Name"
    FIELD FirstName AS CHARACTER LABEL "First_Name"
    FIELD Address AS CHARACTER LABEL "Address"
    FIELD Address2 AS CHARACTER LABEL "Address2"
    FIELD City AS CHARACTER LABEL "City"
    FIELD State AS CHARACTER LABEL "State"
    FIELD PostalCode AS CHARACTER LABEL "Postal_Code"
    FIELD HomePhone AS CHARACTER LABEL "Home_Phone"
    FIELD WorkPhone AS CHARACTER LABEL "Work_Phone"
    FIELD DeptCode AS CHARACTER LABEL "Dept_Code"
    FIELD Position AS CHARACTER LABEL "Position"
    FIELD Birthdate AS DATE LABEL "Birthdate"
    FIELD StartDate AS DATE LABEL "Start_Date"
    FIELD VacationDaysLeft AS INTEGER LABEL "Vacation_Days_Left"
    FIELD SickDaysLeft AS INTEGER LABEL "Sick_Days_Left"
    INDEX pkSeq IS PRIMARY UNIQUE seq
    INDEX idxDeptCode DeptCode
    INDEX idxEmpNo IS UNIQUE EmpNum
    INDEX idxName IS UNIQUE LastName FirstName
    .

DEFINE DATASET dsEmployee FOR ttEmployee.
