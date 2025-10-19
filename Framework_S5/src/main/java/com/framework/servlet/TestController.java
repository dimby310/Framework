package com.framework.servlet;

import jakarta.servlet.http.*;

public class TestController {

    @WebRoute("/hello")
    public void hello(HttpServletRequest request, HttpServletResponse response) throws Exception {
        response.setContentType("text/html;charset=UTF-8");
        response.getWriter().println("<h1>Bonjour depuis TestController !</h1>");
    }

    @WebRoute("/form")
    public void form(HttpServletRequest request, HttpServletResponse response) throws Exception {
        response.setContentType("text/html;charset=UTF-8");
        response.getWriter().println("<h1>Page Formulaire</h1>");
    }
}
