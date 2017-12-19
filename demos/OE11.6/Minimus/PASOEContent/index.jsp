<%@ page language="java" 
         contentType="text/html;charset=UTF-8" 
         pageEncoding="UTF-8" 
         session="true" 
         errorPage="/WEB-INF/jsp/errorPage.jsp"%>
<% // Forward to the home page based on being an
   // development versus a production server instance
    String product = "dev";
    
    product = System.getProperty("psc.as.security.model");
    if (product == null ) {
        product = "default";
    } 

    if ( product.matches("^dev.*") ) {
        // For development server instances, redirect the client to the
        // static/ServerStatus.html static page (aka static/index.html) 
        // that the web application tailoring sets up as the home page.
        // The redirect is a result of the static page needing the 
        // correct location for relative URLs to work.
        response.sendRedirect(request.getScheme() + "://" +
                              request.getServerName() + ":" +
                              request.getServerPort() + 
                              request.getContextPath() + 
                              "/static/index.html");
    } else {
        // For production server instance or an untailored default, forward
        // directly to the home JSP page because it can dynamically insert 
        // the necessary URL path elements.  
        request.getRequestDispatcher("/static/home.jsp").forward(request, response);
    } 
%>
