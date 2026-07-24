package com.example.customer.rest;

import javax.ws.rs.ApplicationPath;
import javax.ws.rs.core.Application;

// Empty subclass: Jersey scans the webapp for @Path resources and @Provider classes.
@ApplicationPath("/api")
public class CustomerApplication extends Application {
}
