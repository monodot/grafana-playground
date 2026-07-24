package com.example.customer.web;

import java.io.IOException;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;

/**
 * Renames the worker thread to include the request path for the duration of the
 * request - a common legacy-app trick. The OTel agent records thread.name on the
 * span, so the renamed thread is visible in the trace.
 */
@WebFilter("/*")
public class ThreadRenameFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        Thread current = Thread.currentThread();
        String originalName = current.getName();
        current.setName(originalName + "-" + ((HttpServletRequest) request).getRequestURI());
        try {
            chain.doFilter(request, response);
        } finally {
            current.setName(originalName);
        }
    }
}
