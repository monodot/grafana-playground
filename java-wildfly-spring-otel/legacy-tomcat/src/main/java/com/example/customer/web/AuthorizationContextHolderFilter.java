package com.example.customer.web;

import java.io.IOException;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;

@WebFilter("/*")
public class AuthorizationContextHolderFilter implements Filter {

    private static final ThreadLocal<String> CONTEXT = new ThreadLocal<>();

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        CONTEXT.set(((HttpServletRequest) request).getHeader("X-User-Id"));
        try {
            chain.doFilter(request, response);
        } finally {
            CONTEXT.remove();
        }
    }
}
