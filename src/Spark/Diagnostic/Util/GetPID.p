/*------------------------------------------------------------------------
    File        : GetPID.p
    Purpose     : Obtain a PID using OS-specific means.
    Description :
    Author(s)   : Dustin Grau
    Created     : Wed Jan 30 14:13:00 EST 2019
    Notes       :
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

procedure GetPID external "/lib64/libc.so.6":
    define return parameter retval as long no-undo.
end procedure.

procedure GetCurrentProcessId external "kernel32.dll":
    define return parameter ppid as long no-undo.
end procedure.
