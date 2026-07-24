package com.example.customer.rest;

import java.util.logging.Level;
import java.util.logging.Logger;

import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.ext.ExceptionMapper;
import javax.ws.rs.ext.Provider;

import com.example.customer.PlatformFaultException;

/**
 * Converts PlatformFaultException into a 500 response, like legacy JAX-RS apps
 * commonly do. Note for the tracing demo: because the exception is HANDLED here,
 * it never escapes to Tomcat - the OTel agent records it on the JAX-RS span
 * where it was thrown, and the server span is marked as an error via the 500.
 */
@Provider
public class PlatformFaultExceptionMapper implements ExceptionMapper<PlatformFaultException> {

    private static final Logger LOG = Logger.getLogger(PlatformFaultExceptionMapper.class.getName());

    @Override
    public Response toResponse(PlatformFaultException exception) {
        LOG.log(Level.SEVERE, exception.getMessage(), exception);
        return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                .type(MediaType.APPLICATION_JSON)
                .entity("{\"error\":\"" + exception.getMessage().replace("\"", "'") + "\"}")
                .build();
    }
}
