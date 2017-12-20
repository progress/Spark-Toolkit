<%@ page language="java" 
         contentType="text/html;charset=UTF-8" 
         pageEncoding="UTF-8" 
         session="false" 
         errorPage="/WEB-INF/jsp/errorPage.jsp"%>
<%
// Forward to protected login page. 
request.getRequestDispatcher("/WEB-INF/jsp/loginPage.jsp").forward(request, response);
%>
