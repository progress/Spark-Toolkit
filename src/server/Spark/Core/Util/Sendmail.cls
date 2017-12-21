/*------------------------------------------------------------------------
    File        : Sendmail.cls
    Purpose     : Common email-sending utility for Windows/Linux.
    Description :
    Author(s)   : Dustin Grau (dgrau@progress.com)
    Created     : Mon Mar 31 17:42:59 EST 2014
    Notes       : Requires either BLAT (Windows) or sendmail (Linux).
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

block-level on error undo, throw.

class Spark.Core.Util.Sendmail:

    define public property IsDevMode as logical no-undo initial false
    get.
    set.

    define public property BlatPath as character no-undo initial "c:\blat.exe"
    get.
    set.

    define public property BlatLog as character no-undo initial "c:\blat.log"
    get.
    set.

    define public property SendmailPath as character no-undo initial "/usr/sbin/sendmail"
    get.
    set.

    define public property SMTPServer as character no-undo initial "localhost"
    get.
    set.

    define public property AttachBinary as character no-undo
    get.
    set.

    define public property AttachText as character no-undo
    get.
    set.

    define public property EmailBody as character no-undo
    get.
    set.

    define public property Recipient as character no-undo
    get.
    set.

    define public property SubjectLine as character no-undo
    get.
    set.

    define public property SendWithBCC as character no-undo
    get ():
        return trim(replace(SendWithBCC, ";", ",")).
    end get.
    set.

    define public property SendWithCC as character no-undo
    get ():
        return trim(replace(SendWithCC, ";", ",")).
    end get.
    set.

    define public property SendFrom as character no-undo
    get ():
        if (SendFrom gt "") ne true then
            return "noreply@yourdomain.com".
        else
            return SendFrom.
    end get.
    set.

    define private variable cCommand   as character no-undo.
    define private variable cFileBody  as character no-undo.

    define stream sMail.


    constructor Sendmail ( ):
        super().
    end constructor.


    /**************************** Private Helper Methods ****************************/


    method private void createTempFile ( input pcPrefix as character ):
        run adecomm/_tmpfile.p (substitute("&1_&2", trim(pcPrefix), mtime), ".html", output cFileBody).
    end method. /* createTempFile */


    method private void removeTempFile ( ):
        if not IsDevMode then do:
            /* Deletes the file, if exists. */
            file-info:file-name = cFileBody.
            if file-info:full-pathname ne ? then
                os-delete value(cFileBody).
        end.

        assign cFileBody = "".
    end method. /* RemoveFile */


    /**************************** Public Helper Methods *****************************/


    method public logical SendEmail ( input  pcSubject   as character,
                                      input  pcEmailBody as character,
                                      input  pcToAddress as character ):
        /* Allows sending of email quickly, using 3 required values. */
        assign
            SubjectLine = pcSubject
            EmailBody   = pcEmailBody
            Recipient   = pcToAddress
            .

        return this-object:SendEmail().
    end method. /* SendEmail */


    method public logical SendEmail ( ):
        define variable cOptions as character no-undo.

        if (SubjectLine gt "") ne true then
            undo, throw new AppError("Subject line missing", -404).

        if (EmailBody gt "") ne true then
            undo, throw new AppError("Email body missing", -404).

        if (Recipient gt "") ne true then
            undo, throw new AppError("Recipient missing", -404).

        createTempFile("_email"). /* Create new email body. */

        output stream sMail to value(cFileBody).
        if opsys eq "WIN32" then do:
            /* Prepare for sending via Blat (Windows). */
            assign EmailBody = replace(EmailBody, "\n", "<br/>").
            if (SendWithCC gt "") eq true then
                assign cOptions = substitute("&1 -cc &2", cOptions, SendWithCC).
            if (SendWithBCC gt "") eq true then
                assign cOptions = substitute("&1 -bcc &2", cOptions, SendWithBCC).
        end.
        else do:
            /* Prepare for sending via sendmail (Linux). */
            put stream sMail unformatted "To: " + Recipient skip.
            if (SendWithCC gt "") eq true then
                put stream sMail unformatted "Cc: " + SendWithCC skip.
            if (SendWithBCC gt "") eq true then
                put stream sMail unformatted "Bcc: " + SendWithBCC skip.
            put stream sMail unformatted "From: " + SendFrom skip.
            put stream sMail unformatted "Subject: " + SubjectLine skip.
            put stream sMail unformatted "MIME-Version: 1.0" skip.
            put stream sMail unformatted 'Content-Type: text/html; charset="us-ascii"' skip.
            put stream sMail unformatted "Content-Disposition: inline" skip.
        end.
        put stream sMail unformatted EmailBody skip.
        output stream sMail close.

        /* Create the mail command as based on operating system. */
        if opsys eq "WIN32" then
            assign cCommand = substitute('&1 &2 -noh -noh2 -server &3 -to &4 &5 -f &6 -subject "&7" -charset utf-8 -html > &8',
                                         BlatPath, cFileBody, SMTPServer, Recipient, cOptions, SendFrom, SubjectLine, BlatLog).
        else
            assign cCommand = substitute("&1 -t -i < &2", SendmailPath, cFileBody).

        /* Send the mail via the command line built above. */
        message substitute("Sending Email: &1", cCommand).
        os-command silent value(cCommand).

        return true.

        finally:
            /* Clear stuff out for the next call. */
            assign
                AttachBinary = ""
                AttachText   = ""
                SendWithBCC  = ""
                SendWithCC   = ""
                SendFrom     = ""
                .

            removeTempFile().
        end finally.
    end method. /* SendEmail */

end class.