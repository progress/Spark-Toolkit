<%@ page language="java" 
         contentType="text/html;charset=UTF-8" 
         pageEncoding="UTF-8" 
         session="false" 
         errorPage="/WEB-INF/jsp/errorPage.jsp"%>
<html>
<head>
<title>Progress Application Server Login</title>
<link rel="stylesheet" type="text/css" href="<%=request.getContextPath()%>/static/commonStyle.css" media="screen" />
</head>
<body>
<%@ include file="/static/commonPageHeader.html" %>
    <hr>
    <b> Progress Applicaiton Server user login: </b>
    <br>
<%
    String lmodel = application.getInitParameter("contextConfigLocation"); 
    if ( lmodel.matches(".*oeablSecurity-form.*") ) {
%>
    <form action="j_spring_security_check" method="POST">
        <input type='text' name='j_username' /><br>
        <input type='password' name='j_password' /><br>
    <br>
        <input name="submit" type="submit" value="Login" />
    </form>
<%
    } else {
%>
    <br>
    <b>Form login is not compatible with the security policy configuration</b>
<%
    }
%>
    <p>
    <%@ include file="/static/commonPageFooter.html" %>
</body>
</html>
