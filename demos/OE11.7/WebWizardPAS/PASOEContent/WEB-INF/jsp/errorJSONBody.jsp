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
<%-- Begin editable JSON reponse template: --%>
<%@  include file="loadErrorData.jsp" %>{ 
"error_code": <%=request.getAttribute("psc.as.attr.errorCode")%>
, "status_txt": "<%=request.getAttribute("psc.as.attr.errorMessage")%>"
, "error_details": {
  "remote_user": "<%=request.getRemoteUser()%>"
, "user_principal": "<%=request.getUserPrincipal()%>"
, "url_scheme": "<%=request.getScheme()%>"
, "remote_addr": "<%=request.getRemoteAddr()%>"
, "server_name": "<%=request.getServerName()%>"
, "product_type": "<%=request.getAttribute("psc.as.attr.product")%>"
, "http_status": <%=(Integer)request.getAttribute("javax.servlet.error.status_code")%> 
, "error_detail": "<%=request.getAttribute("psc.as.attr.errorDetail")%>"
}
, "debug_details": {
  "http_method": "<%=request.getMethod()%>"
, "web_application": "<%=request.getAttribute("psc.as.attr.webApp")%>"
, "transport": "<%=request.getAttribute("psc.as.attr.transport")%>"
, "request_url": "<%=request.getAttribute("psc.as.attr.requrl")%>"
, "path_info": "<%=request.getPathInfo()%>"
, "servlet": "<%=(String)request.getAttribute("javax.servlet.error.servlet_name")%>"
, "uri": "<%=(String)request.getAttribute("javax.servlet.error.request_uri")%>"
, "exception_class": "<%=request.getAttribute("psc.as.attr.exceptionName")%>"
, "exception_message": "<%=request.getAttribute("psc.as.attr.exceptionMessage")%>"
, "exception_stack_trace": "<%=request.getAttribute("psc.as.attr.exceptionStack")%>"
}
}
<%-- End editable JSON reponse template: --%>

