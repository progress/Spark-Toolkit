<%@ page language="java" 
         contentType="text/html;charset=UTF-8" 
         pageEncoding="UTF-8" 
         session="true" 
         errorPage="/WEB-INF/jsp/errorPage.jsp"%>
<% // Simply redirect to the wizard application page.
    response.sendRedirect(request.getScheme() + "://" +
                          request.getServerName() + ":" +
                          request.getServerPort() + 
                          request.getContextPath() + 
                          "/static/wizard.html");
%>
