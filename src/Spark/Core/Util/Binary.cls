/*------------------------------------------------------------------------
    File        : Binary utilities
    Purpose     :
    Syntax      :
    Description :
    Author(s)   : Dustin Grau
    Created     : Wed Oct 18 14:59:57 EDT 2017
    Notes       :
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

block-level on error undo, throw.

class Spark.Core.Util.Binary use-widget-pool:

    method public static integer BinaryAND ( input piOperand1 as integer,
                                             input piOperand2 as integer ):
        define variable iByteLoop  as integer no-undo.
        define variable iResult    as integer no-undo.
        define variable lFirstBit  as logical no-undo.
        define variable lSecondBit as logical no-undo.

        assign iResult = 0.

        do iByteLoop = 1 to 32: /* 4x8 */
            /* Find state (true / false) of each integer's byte. */
            assign
                lFirstBit  = get-bits(piOperand1, iByteLoop, 1) = 1
                lSecondBit = get-bits(piOperand2, iByteLoop, 1) = 1
                .

            /* AND each bit */
            if (lFirstBit and lSecondBit) then
                assign iResult = iResult + exp(2, iByteLoop - 1).
        end. /* do iByteLoop */

        return iResult.
    end method. /* BinaryAND */


    method public static integer BinaryOR ( input piOperand1 as integer,
                                            input piOperand2 as integer ):
        define variable iByteLoop  as integer no-undo.
        define variable iResult    as integer no-undo.
        define variable lFirstBit  as logical no-undo.
        define variable lSecondBit as logical no-undo.

        assign iResult = 0.

        do iByteLoop = 1 to 32: /* 4x8 */
            /* Find state (true / false) of each integer's byte. */
            assign
                lFirstBit  = get-bits(piOperand1, iByteLoop, 1) = 1
                lSecondBit = get-bits(piOperand2, iByteLoop, 1) = 1
                .

            /* OR each bit */
            if (lFirstBit or lSecondBit) then
                assign iResult = iResult + exp(2, iByteLoop - 1).
        end. /* do iByteLoop */

        return iResult.
    end method. /* BinaryOR */


    method public static integer BinaryXOR ( input piOperand1 as integer,
                                             input piOperand2 as integer ):
        define variable iByteLoop  as integer no-undo.
        define variable iResult    as integer no-undo.
        define variable lFirstBit  as logical no-undo.
        define variable lSecondBit as logical no-undo.

        assign iResult = 0.

        do iByteLoop = 1 to 32: /* 4x8 */
            /* Find state (true / false) of each integer's byte. */
            assign
                lFirstBit  = get-bits(piOperand1, iByteLoop, 1) = 1
                lSecondBit = get-bits(piOperand2, iByteLoop, 1) = 1
                .

            /* XOR each bit */
            if (lFirstBit and not lSecondBit) or
               (lSecondBit and not lFirstBit) then
                assign iResult = iResult + exp(2, iByteLoop - 1).
        end. /* do iByteLoop */

        return iResult.
    end method. /* BinaryXOR */


    method public static integer ShiftLeft ( input piOperand as integer,
                                             input piBits    as integer ):
        define variable cBinary as character no-undo.

        /* Cannot shift unless bits are powers of 2. */
        if (piBits modulo 2) ne 0 then return piOperand.

        /* Convert an integer value to binary. */
        assign cBinary = Spark.Core.Util.Convert:IntToBin(piOperand).

        /* Shift left by padding right with zeroes. */
        assign cBinary = substitute("&1&2", cBinary, fill("0", piBits)).

        /* Return shifted value as integer. */
        return Spark.Core.Util.Convert:BinToInt(cBinary).
    end method. /* ShiftLeft */

end class.