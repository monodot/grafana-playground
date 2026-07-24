package com.example.customer.routing;

import java.util.HashMap;
import java.util.Map;

/**
 * A tiny stand-in for a legacy routing component: it knows which backend
 * directory serves each customer region. Regions that were never registered
 * fail with the nested exception chain typical of old platform code.
 */
public final class RegionRoutingTable {

    private static final Map<String, String> ROUTES = new HashMap<>();

    static {
        ROUTES.put("EMEA", "ldap://directory-emea.internal.example:10389");
        ROUTES.put("APAC", "ldap://directory-apac.internal.example:10389");
    }

    private RegionRoutingTable() {
    }

    public static String endpointFor(String region) {
        String endpoint = ROUTES.get(region);
        if (endpoint == null) {
            try {
                throw new RegionNotRegisteredException(region);
            } catch (RegionNotRegisteredException e) {
                throw new DirectoryLookupException(region, ROUTES.keySet(), e);
            }
        }
        return endpoint;
    }
}
