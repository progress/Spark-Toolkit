<%@ page language="java" 
         contentType="text/html;charset=UTF-8" 
         pageEncoding="UTF-8" 
         session="false"
         isErrorPage="true" 
         trimDirectiveWhitespaces="true"
         errorPage="/WEB-INF/jsp/exceptionPage.jsp"
         import="java.io.*"
         import="java.util.*"
         import="java.system.*" %>
 <%-- Java scriptlet to cleanup raw input properties and attributes used as tokens 
      by the HTML template found at the end of this file. --%>
 <%
    // Generate the dynamic body content
    try {
        // Detail level: 0 Use product type defaults
        //               The following values 1 - 4 override the
        //               default product type values
        //               1 Terse    (least information)
        //               2 verbose  (more information)
        //               3 debug    (add more jsp page debug info)
        String      errorMessage = "";
        int         detailLevel = 0;
        String      product = "dev";
        String      requrl = "unknown";
        String      webAppName = "/ROOT";
        int         errorCode = 0;
        String      errcodeStr = "0";
        String      transport = "unknown";
        Throwable   appException = null;
        String      exceptionName = "";
        String      exceptionMessage = "";
        String      exceptionStack = "";
        String      errorDetail = "";
        String      statusDetail = "";
        String      errorFormat = (String)request.getAttribute("psc.as.attr.errorFormat");

        // Load the development/production setting for the initial
        // detailLevel.
        product = System.getProperty("psc.as.security.model");
        if (product == null ) {
            product = "default";
        } else {
            if ( product.matches("^dev.*") ) {
                product = "dev";
                detailLevel = 3;
            } else if ( product.matches("^prod.*") ) {
                product = "prod";
                detailLevel = 1;
            } else {
                product = "default";
                detailLevel = 2;
            }
        }

        // Load any specific detailLevel from the web application env
        try { 
            String sdetailLevel = application.getInitParameter("detailLevel"); 
            if ( sdetailLevel != null ) {
                int cfgDetailLevel = Integer.parseInt(sdetailLevel);
                if ( cfgDetailLevel > 0 ) {
                    detailLevel = cfgDetailLevel;
                }
            }
        } catch(Throwable th) {
        }

        // Cleanup the web application name, for the root app a blank
        // is returned, but we want to pass in ROOT in that case.
        String cp = request.getContextPath();
        if ( cp != null &&
             cp.length() > 0) {
            webAppName = cp;
        }
        
        // Bundle together the error information for writing to the page
        if(pageContext != null) {
            ErrorData       errctx = null;

            // Get the implicit error data object for this request
            try {
                errctx = pageContext.getErrorData();
            } catch(NullPointerException ne) {

                // Sometimes this call causes a NullPointerException (PageContext.java:514)
                // Catch and ignore it.. it effectively means we can't use the ErrorData
            }
            
            // Prepare error report
            if(errctx != null) {
                // Unload the basic error object fields
                requrl = errctx.getRequestURI();
                errorCode = errctx.getStatusCode();
                transport = errctx.getServletName();
                appException = errctx.getThrowable();

                errorDetail = (String)request.getAttribute("javax.servlet.error.message");

                // Cleanup some null values with defaults
                if ( requrl == null ) requrl = "/";
                if (transport == null ) transport = "default";

                // The building of the error information is divided into 
                // HTTP status codes and Exceptions
                if ( appException != null ) {
                    StringBuilder   sb = new StringBuilder();
                    // Handle application excpetions here
                    if(appException.getMessage() != null && 
                       appException.getMessage().indexOf("Exception in JSP") != -1) {
                        sb = new StringBuilder("An error occurred in a JSP file ...\n\n<pre>" + 
                                    appException.getMessage() + "</pre>");
                    } else {
                        String ecls = "";
                        if ( detailLevel > 1 ) {
                            ecls = appException.getClass().getName() + " ; ";
                        } 
                        sb = new StringBuilder( ecls + appException.getMessage());
                    }
                    errorDetail = sb.toString().trim();

                    if ( detailLevel > 2 ) {
                        sb.setLength(0);
                        StackTraceElement stea[] = appException.getStackTrace();
                        if ( errorFormat == null || !errorFormat.equals("json") ) {
                            // Format for HTML
                            for (StackTraceElement ste : stea ) {
                                sb.append("<br>at ");
                                sb.append(ste.toString());
                            }
                        } else {
                            // Format for JSON
                            String          fsep = "";
                            sb.append("[ \n");
                            for (StackTraceElement ste : stea ) {
                                sb.append(fsep);
                                sb.append("\"");
                                sb.append(ste.toString());
                                sb.append("\"\n");
                                fsep = ",";
                            }
                            sb.append("\n]\n");
                        }
                        exceptionStack = sb.toString().trim();
                    }
                    // Save off individual exception fields rather than needing to
                    // access the exception built-in object
                    exceptionName = appException.getClass().getName();
                    exceptionMessage = appException.getMessage();
                } 
               
                // Now load error description based on the status code and
                // write it to the page
                if ( errorCode == 0 ) {
                    // Sometimes the error object does not include the
                    // status code ( returns zero ), so try the 
                    // built-in servlet attributes
                    errcodeStr = (String)request.getAttribute("javax.servlet.error.status_code");
                    if ( errcodeStr != null ) {
                        errorCode = Integer.parseInt(errcodeStr);
                    } else {
                        String pageErrorCode = request.getParameter("statusCode"); 
                        if ( pageErrorCode != null ) {
                            errorCode = Integer.parseInt(pageErrorCode);
                        }
                    }
                }

                // Load the static HTTP status code description
                // Properties file lookup key...
                errcodeStr = "code" + Integer.toString(errorCode);

                try {
                    String descFile = "descFile";
                    // Determine which static text file to load from
                    if (detailLevel < 2  ) {
                        descFile = "/WEB-INF/jsp/httpCodeDesc-terse.properties";
                    } else {
                        descFile = "/WEB-INF/jsp/httpCodeDesc-verbose.properties";
                    } 
                    // Open properties file and load the static
                    // error code text
                    InputStream stream = 
                            application.getResourceAsStream(descFile);
                    Properties props = new Properties();
                    props.load(stream);
                    statusDetail = props.getProperty(errcodeStr);
                    // if the error code text is not found, then get 
                    // the default error code zero (0)
                    if ( statusDetail == null ) {
                        String tmpDetail = props.getProperty("code0");
                        if ( tmpDetail == null ) {
                            tmpDetail = "undefined status code ";
                        } 
                        statusDetail = tmpDetail + errorCode;
                    }
                } catch ( Throwable thr ) {
                    statusDetail = "undefined status code description";
                    application.log("HTTP status code descriptions not available: " +
                        thr.toString());
                }

                // Adjust the error message line according to the amount of detail needed
                if (detailLevel < 2 ) {
                    request.setAttribute( "psc.as.attr.errorMessage", statusDetail.trim() );
                } else {
                    request.setAttribute( "psc.as.attr.errorMessage", errorCode + " - " + 
                            statusDetail.trim() + " - " + request.getMethod() + " " + requrl);
                } 
                
                // Set all the other attributes that are accessible via JSP tags
                request.setAttribute("psc.as.attr.detailLevel", detailLevel);
                request.setAttribute("psc.as.attr.product", product);
                request.setAttribute("psc.as.attr.requrl", requrl);
                request.setAttribute("psc.as.attr.errorCode", errorCode);
                request.setAttribute("psc.as.attr.errorDetail", errorDetail);
                request.setAttribute("psc.as.attr.errcodeStr", errcodeStr);
                request.setAttribute("psc.as.attr.transport" , transport);
                request.setAttribute("psc.as.attr.webApp" , webAppName);
                request.setAttribute("psc.as.attr.exceptionName", exceptionName);
                request.setAttribute("psc.as.attr.exceptionMessage", exceptionMessage );
                request.setAttribute("psc.as.attr.exceptionStack", exceptionStack );

            } else {
                application.log( "Internal page generation error - no error context available");
            }
        } else {
            application.log( "Internal page generation error - no request context available");
        }
    } catch(Throwable e2) {

        // Error in error handler
        application.log("An internal error has occurred in the error page.\n\n");
        application.log("Please copy the following details and provide it to technical send support.\n");
        application.log(e2.toString());
    }
%>
