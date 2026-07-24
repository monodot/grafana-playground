package com.example.customer.service;

import java.util.List;

import com.example.customer.PlatformFaultException;
import com.example.customer.routing.DirectoryLookupException;

public class CustomerService {

    private final AccountRepository repository = new AccountRepository();

    public List<String> findAccounts(String region) {
        try {
            return repository.findAccounts(region);
        } catch (DirectoryLookupException e) {
            throw new PlatformFaultException(e.getMessage(), e);
        }
    }
}
