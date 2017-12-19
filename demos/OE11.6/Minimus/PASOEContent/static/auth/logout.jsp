<%@ page language="java" 
         contentType="text/html;charset=UTF-8" 
         pageEncoding="UTF-8" 
         session="false" 
         errorPage="/WEB-INF/jsp/errorPage.jsp"%>
<%
// Forward to protected logout page. 
request.getRequestDispatcher("/WEB-INF/jsp/logoutPage.jsp").forward(request, response);
%>


