<%@ page language="java" 
         contentType="text/html;charset=UTF-8" 
         pageEncoding="UTF-8" 
         session="false" 
         trimDirectiveWhitespaces="true"
         errorPage="/WEB-INF/jsp/errorPage.jsp"%>
<html>
<head>
<title>Progress Application Home</title>
<link rel="stylesheet" type="text/css" href="<%=request.getContextPath()%>/static/commonStyle.css" media="screen" />
<meta http-equiv="Cache-Control" content="no-store" />
<%@ taglib prefix="sec" uri="/WEB-INF/security.tld" %>
</head>
<body>
<%@ include file="/static/commonPageHeader.html" %>

<h2><b>Welcome to Progress Application Server for OpenEdge</b></h2>
<hr>
<b>Current session:</b>
<table>
<tr><td><b>RemoteUser:</b></td> <td><%= request.getRemoteUser()%> </td> </tr>
<tr><td style="vertical-align:top"><b>Principal:</b></td> <td><%= request.getUserPrincipal()%> </td> </tr>
<tr><td><b>RemoteAddr:</b></td> <td><%= request.getRemoteAddr()%> </td> </tr>
<tr><td><b>ServerName:</b></td> <td><%= request.getServerName()%> </td> </tr>
<br>
<%
    String lmodel = application.getInitParameter("contextConfigLocation"); 
    if ( ! lmodel.matches(".*oeablSecurity-anonymous.*") ) {
%>
<%-- Include login/logout info only for non-anonymous model policies --%>
<sec:authorize access="isAuthenticated()">
   <tr> <td><br/></td> </tr>
   <tr> <td><b>Login:</b></td> <td>yes</td> </tr>
   <tr> <td><b>Username:</b></td> <td><sec:authentication property="principal.username" /> </td> </tr>
   <tr> <td><b>Authorities:</b></td> <td><sec:authentication property="principal.authorities" /> </td> </tr>
   </table>
   <% if ( lmodel.matches(".*oeablSecurity-form.*") ) { %>
       <br><br>
       <a href="<%=request.getContextPath()%>/static/auth/logout.jsp"
          target="_parent"> <button>Logout...</button> </a>
   <% } %>
</sec:authorize>
<sec:authorize access="isAnonymous()">
   <tr> <td><br/></td> </tr>
   <tr><td><b>Login:</b></td> <td> no </td> </tr>
   <tr><td><b>Username:</b></td> <td> <sec:authentication property="principal" /> </td> </tr>
    </table>
   <% if ( lmodel.matches(".*oeablSecurity-form.*") ) { %>
       <br><br>
       <a href="<%=request.getContextPath()%>/static/auth/login.jsp"
          target="_parent"> <button>Login...</button> </a>
   <% } %>
</sec:authorize>
<% } else { %>
<%-- Show anonymous policy as not/applicable --%>
    </table>
    <br>Login: N/A
<% } %>
<br>
<p>
<%@ include file="/static/commonPageFooter.html" %>
</body>
</html>
