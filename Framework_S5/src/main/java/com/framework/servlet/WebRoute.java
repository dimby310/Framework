package com.framework.servlet;

import java.lang.annotation.*;

@Retention(RetentionPolicy.RUNTIME)   
@Target(ElementType.METHOD)           
public @interface WebRoute {
    String value();                   
}
