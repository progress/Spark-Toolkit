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
 <%-- Java scriptlet to cleanup raw input properties and attributes used as 
      psc.as.attr.xxxxx tokens by the HTML template found in this file. --%>
<%@  include file="loadErrorData.jsp" %>

<%-- Begin Editable HTML page template: --%>
<p><%=request.getAttribute("psc.as.attr.errorMessage")%>

<% if ( (Integer)request.getAttribute("psc.as.attr.detailLevel") > 1) { %> <%-- Add verbose information here --%>
<p>
<table>
<tr><td><b>Error details</b> </td> </tr>
<tr><td><b>Remote user:</b></td> <td> <%=request.getRemoteUser()%> </td> </tr>
<tr><td><b>User principal:</b></td> <td> <%=request.getUserPrincipal()%> </td> </tr>
<tr><td><b>Scheme:</b></td> <td> <%=request.getScheme()%> </td> </tr>
<tr><td><b>Remote address:</b></td> <td> <%=request.getRemoteAddr()%> </td> </tr>
<tr><td><b>Server name:</b></td> <td> <%=request.getServerName()%> </td> </tr>
<tr><td><b>PASOE product type:</b></td> <td> <%=request.getAttribute("psc.as.attr.product")%> </td> </tr>
<tr><td><b>HTTP status:</b></td> <td> <%=(Integer)request.getAttribute("javax.servlet.error.status_code")%> </td> </tr>
<tr><td><b>Error detail:</b></td> <td> <%=request.getAttribute("psc.as.attr.errorDetail")%> </td> </tr>
</table>
<% }; %> <%-- End of Error Details --%>

<% if ( (Integer)request.getAttribute("psc.as.attr.detailLevel") > 2) { %> <%-- Add more debug information here --%>
<table>
<tr> <td><br/></td> </tr>
<tr><td><b>Debug details</b> </td> </tr>
<tr><td><b>HTTP method:</b></td> <td> <%=request.getMethod()%>  </td> </tr>
<tr><td><b>Web application:</b></td> <td> <%=request.getAttribute("psc.as.attr.webApp")%> </td> </tr>
<tr><td><b>Transport:</b></td> <td> <%=request.getAttribute("psc.as.attr.transport")%> </td> </tr>
<tr><td><b>Request URL:</b></td> <td> <%=request.getAttribute("psc.as.attr.requrl")%> </td> </tr>
<tr><td><b>Path info:</b></td> <td> <%=request.getPathInfo()%> </td> </tr>
<tr><td><b>Servlet name:</b></td> <td> <%=(String)request.getAttribute("javax.servlet.error.servlet_name")%> </td> </tr>
<tr><td><b>URI:</b></td> <td> <%=(String)request.getAttribute("javax.servlet.error.request_uri")%> </td> </tr>
<tr><td><b>Exception class:</b></td> <td> <%=request.getAttribute("psc.as.attr.exceptionName")%> </td> </tr>
<tr><td><b>Exception message:</b></td> <td> <%=request.getAttribute("psc.as.attr.exceptionMessage")%> </td> </tr>
<tr><td style="vertical-align:top"><b>Exception stack trace:</b></td> <td> <%=request.getAttribute("psc.as.attr.exceptionStack")%> </td> </tr>
</table>
<% }; %>

<%-- End Editable HTML page template: --%>

