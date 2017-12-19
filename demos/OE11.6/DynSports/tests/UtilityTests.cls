/*------------------------------------------------------------------------
    File        : UtilityTests
    Purpose     :
    Syntax      :
    Description :
    Author(s)   : dugrau@progress.com
    Created     : Thu May 30 19:10:52 EDT 2017
    Notes       :
  ----------------------------------------------------------------------*/

&global-define test_username dev@spark
&global-define allowed_roles PSCUser,EndUser
&global-define domain_passkey oech1::23222e35397562

using Progress.Lang.* from propath.
using Progress.Json.ObjectModel.* from propath.

block-level on error undo, throw.

class tests.UtilityTests inherits tests.PMFOUnit:

    define private variable hCPO as handle no-undo.

	/*------------------------------------------------------------------------------
	 Purpose: Start up the PMFO stack similar to a session of the MSAS agent.
	 Notes:
	------------------------------------------------------------------------------*/
	@Before.
	method public void before ( ):
        this-object:StartPMFO().
	end method.

    /*------------------------------------------------------------------------------
     Purpose: Shut down the PMFO stack similar to a session of the MSAS agent.
     Notes:
    ------------------------------------------------------------------------------*/
    @After.
    method public void after ( ):
        this-object:StopPMFO().

        finally:
            delete object hCPO no-error.
        end finally.
    end method.


    /*------------------------------------------------------------------------------
        Purpose:
        Notes:
    ------------------------------------------------------------------------------*/
    @Setup.
    method public void setUp ( ):
    end method.

    /*------------------------------------------------------------------------------
        Purpose:
        Notes:
    ------------------------------------------------------------------------------*/
    @TearDown.
    method public void tearDown ( ):
    end method.

    /*------------------------------------------------------------------------------
        Purpose: Confirm the binary to integer conversions work.
        Notes:
    ------------------------------------------------------------------------------*/
    @Test.
    method public void testBinaryConversion ( ):
        define variable cTest as character no-undo extent 64.
        define variable iX    as integer   no-undo.

        /* Test for zero. */
        OpenEdge.Core.Assert:Equals(0, Spark.Core.Util.Convert:BinToInt("0")).

        do iX = 1 to extent(cTest):
            assign cTest[iX] = Spark.Core.Util.Convert:IntToBin(iX).
        end.

        do iX = 1 to extent(cTest):
            /* Converted value should match the original. */
            OpenEdge.Core.Assert:Equals(iX, Spark.Core.Util.Convert:BinToInt(cTest[iX])).
        end.
    end method.

    /*------------------------------------------------------------------------------
        Purpose: Confirm the Base32 encode works.
        Notes:
    ------------------------------------------------------------------------------*/
    @Test.
    method public void testBase32Encode ( ):
        /* Encoded value should match a known value. */
        OpenEdge.Core.Assert:Equals("JBSWY3DPEFLW64TMMQQQ====", Spark.Core.Util.Base32:EncodeData("Hello!World!")).
    end method.

    /*------------------------------------------------------------------------------
        Purpose: Confirm the Base32 decode works.
        Notes:
    ------------------------------------------------------------------------------*/
    @Test.
    method public void testBase32Decode ( ):
        /* Decoded value should match a known value. */
        OpenEdge.Core.Assert:Equals("Hello!World!", Spark.Core.Util.Base32:DecodeData("JBSWY3DPEFLW64TMMQQQ====")).
    end method.

    /*------------------------------------------------------------------------------
        Purpose: Confirm the Base32 encode/decode works together.
        Notes:
    ------------------------------------------------------------------------------*/
    @Test.
    method public void testBase32 ( ):
        define variable cOriginal as character no-undo initial "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789".
        define variable cEncoded  as character no-undo.
        define variable cDecoded  as character no-undo.

        /* Encode and decode the given original value. */
        assign cEncoded = Spark.Core.Util.Base32:EncodeData(cOriginal).
        log-manager:write-message(substitute("Base32-Encoded &1 as &2", cOriginal, cEncoded)).
        assign cDecoded = Spark.Core.Util.Base32:DecodeData(cEncoded).
        log-manager:write-message(substitute("Base32-Decoded &1 as &2", cEncoded, cDecoded)).

        /* Encoded-Decoded value should match the original. */
        OpenEdge.Core.Assert:Equals(cOriginal, cDecoded).
    end method.

    /*------------------------------------------------------------------------------
        Purpose: Confirm the Base32 conversion to hex works.
        Notes:
    ------------------------------------------------------------------------------*/
    @Test.
    method public void testBase32Hex ( ):
        /* Converted value should match a known value. */
        OpenEdge.Core.Assert:Equals("48656c6c6f21deadbeef", Spark.Core.Util.Base32:ConvertToHex("JBSWY3DPEHPK3PXP")).
    end method.

end class.