package com.framework.servlet;

import jakarta.servlet.http.*;
import jakarta.servlet.*;
import java.io.*;
import java.lang.reflect.Method;

public class FrontServlet extends HttpServlet {

    private Class<?>[] controllers = { TestController.class };

    @Override
    protected void service(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String url = request.getRequestURI();
        String contextPath = request.getContextPath();
        String path = url.substring(contextPath.length());

        System.out.println("URL demandee : " + path);

        InputStream resourceStream = getServletContext().getResourceAsStream(path);

        if (resourceStream != null) {
            String mimeType = getServletContext().getMimeType(path);
            if (mimeType == null) mimeType = "application/octet-stream";

            response.setContentType(mimeType);

            try (OutputStream os = response.getOutputStream()) {
                byte[] buffer = new byte[8192];
                int bytesRead;
                while ((bytesRead = resourceStream.read(buffer)) != -1) {
                    os.write(buffer, 0, bytesRead);
                }
            } finally {
                resourceStream.close();
            }

            System.out.println("Fichier statique envoye avec succes : " + path);

        } else {
            boolean found = false;

            for (Class<?> cls : controllers) {
                try {
                    Object obj = cls.getDeclaredConstructor().newInstance();
                    for (Method method : cls.getDeclaredMethods()) {
                        if (method.isAnnotationPresent(WebRoute.class)) {
                            WebRoute route = method.getAnnotation(WebRoute.class);
                            if (route.value().equals(path)) {
                                method.invoke(obj, request, response);
                                found = true;
                                return;
                            }
                        }
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            if (!found) {
                response.setContentType("text/html;charset=UTF-8");
                response.setCharacterEncoding("UTF-8");

                PrintWriter out = response.getWriter();
                out.println("<!DOCTYPE html>");
                out.println("<html lang='fr'>");
                out.println("<head><meta charset='UTF-8'><title>FrontServlet - URL Inconnue</title></head>");
                out.println("<body>");
                out.println("<h1>URL Inconnue</h1>");
                out.println("<p><strong>URL complete :</strong> " + url + "</p>");
                out.println("<p><strong>Chemin relatif :</strong> " + path + "</p>");
                out.println("<p><strong>Methode HTTP :</strong> " + request.getMethod() + "</p>");
                out.println("<p><strong>Contexte :</strong> " + contextPath + "</p>");
                out.println("<p><strong>Timestamp :</strong> " + new java.util.Date() + "</p>");
                out.println("<p><em>Cette page est generee dynamiquement par le Framework MVC</em></p>");
                out.println("</body></html>");
                out.close();
            }
        }
    }

    @Override
    public void init() throws ServletException {
        System.out.println("=========================================================");
        System.out.println("FrontServlet initialise");
        System.out.println("Roles :");
        System.out.println("   - Servir les fichiers statiques (HTML, CSS, JS, images)");
        System.out.println("   - Capturer les URLs dynamiques pour les controleurs (@WebRoute)");
        System.out.println("=========================================================");
    }
}