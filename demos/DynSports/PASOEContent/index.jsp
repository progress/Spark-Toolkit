<%@ page language="java"
         contentType="text/html;charset=UTF-8"
         pageEncoding="UTF-8"
         session="true"
         errorPage="/WEB-INF/jsp/errorPage.jsp"%>
<% // Just redirect to the application login.
    response.sendRedirect(request.getScheme() + "://" +
                          request.getServerName() + ":" +
                          request.getServerPort() +
                          request.getContextPath() +
                          "/static/login.html");
%>
