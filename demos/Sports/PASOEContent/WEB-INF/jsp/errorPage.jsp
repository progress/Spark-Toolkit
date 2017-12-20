<%@ page language="java" 
         contentType="text/html;charset=UTF-8" 
         pageEncoding="UTF-8" 
         session="false"
         isErrorPage="true" 
         trimDirectiveWhitespaces="true"
         import="java.io.*"
         import="java.util.*"
         import="java.system.*" %>
<%@ taglib prefix="sec" uri="/WEB-INF/security.tld" %>
<%
    String acceptHeader = request.getHeader("accept");
    if ( acceptHeader != null && acceptHeader.matches("^(.*,|)application/(|[\\w\\.]+\\+)json($|,.*)") ) {
        request.setAttribute("psc.as.attr.errorFormat", "json");
        response.setContentType("application/json;charset=UTF-8");
%>
<%@  include file="errorJSONBody.jsp" %>
<%
    } else {
        request.setAttribute("psc.as.attr.errorFormat", "html");
%>
<html>
<head>
<title>Progress Application Server Error</title>
<link rel="stylesheet" type="text/css" href="<%= request.getContextPath()%>/static/commonStyle.css" media="screen" />
<meta http-equiv="Cache-Control" content="no-store" />
</head>
<body>
<%@  include file="errorPageHeader.jsp" %>
<%@  include file="errorPageBody.jsp" %>
<%@  include file="errorPageFooter.jsp" %>
</body>
</html>
<%
    }
%>
