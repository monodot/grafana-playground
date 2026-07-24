package com.example.customer.rest;

import java.util.List;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

import com.example.customer.service.CustomerService;

@Path("/customers/{region}/accounts")
public class CustomerAccountResource {

    private final CustomerService service = new CustomerService();

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public String findAccounts(@PathParam("region") String region) {
        List<String> accounts = service.findAccounts(region);
        StringBuilder json = new StringBuilder("{\"region\":\"").append(region).append("\",\"accounts\":[");
        for (int i = 0; i < accounts.size(); i++) {
            if (i > 0) {
                json.append(',');
            }
            json.append('"').append(accounts.get(i)).append('"');
        }
        return json.append("]}").toString();
    }
}
