package com.example.customer.routing;

public class RegionNotRegisteredException extends RuntimeException {

    public RegionNotRegisteredException(String region) {
        super("Region '" + region + "' is not present in the routing table");
    }
}
