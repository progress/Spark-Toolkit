<%@ page language="java" 
         contentType="text/html;charset=UTF-8" 
         pageEncoding="UTF-8" 
         session="false" 
         errorPage="/WEB-INF/jsp/errorPage.jsp"%>
<% // Forward to the home page 
request.getRequestDispatcher("/static/wizard.html").forward(request, response);
%>
