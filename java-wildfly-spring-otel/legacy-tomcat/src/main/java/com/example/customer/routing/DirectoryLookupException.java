package com.example.customer.routing;

import java.util.Set;

public class DirectoryLookupException extends RuntimeException {

    public DirectoryLookupException(String region, Set<String> available, Throwable cause) {
        super("No directory endpoint is registered for region [" + region + "]. "
                + "Currently registered regions: " + available + ". "
                + "Add the region to directory-routes.xml and reload the routing table "
                + "before enabling traffic for it.", cause);
    }
}
