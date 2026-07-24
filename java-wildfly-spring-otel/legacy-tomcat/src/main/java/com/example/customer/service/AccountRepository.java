package com.example.customer.service;

import java.util.Arrays;
import java.util.List;

import com.example.customer.routing.RegionRoutingTable;

/**
 * Pretends to talk to a per-region customer directory. Opening the connection
 * resolves the region's endpoint from the routing table - which is where
 * unregistered regions blow up, a few frames deep, like a real backend
 * integration would.
 */
public class AccountRepository {

    public List<String> findAccounts(String region) {
        openConnection(region);
        return Arrays.asList(region.toLowerCase() + "-retail", region.toLowerCase() + "-corporate",
                region.toLowerCase() + "-private");
    }

    private void openConnection(String region) {
        resolveEndpoint(region);
    }

    private void resolveEndpoint(String region) {
        RegionRoutingTable.endpointFor(region.toUpperCase());
    }
}
