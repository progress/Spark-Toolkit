/* Version-aware include to add various class directives */

&IF KEYWORD-ALL('block-level') EQ 'block-level' &THEN
block-level on error undo, throw.
&ELSEIF KEYWORD-ALL('routine-level') EQ 'routine-level' &THEN
routine-level on error undo, throw.
&ENDIF
&GLOBAL-DEFINE THROW ON ERROR UNDO, THROW
&GLOBAL-DEFINE CAN_USE_REFLECTION (lookup(substring(proversion, 1, 4), "11.0,11.1,11.2,11.3,11.4,11.5") = 0)