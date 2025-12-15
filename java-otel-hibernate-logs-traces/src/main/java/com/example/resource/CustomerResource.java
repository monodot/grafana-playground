package com.example.resource;

import com.example.entity.Customer;
import com.example.util.HibernateUtil;
import jakarta.persistence.EntityManager;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

@Path("/api/customers")
public class CustomerResource {

    @POST
    @Consumes({MediaType.APPLICATION_JSON, MediaType.APPLICATION_FORM_URLENCODED})
    @Produces(MediaType.APPLICATION_JSON)
    public Response createCustomer(
            @FormParam("name") String name,
            @FormParam("email") String email,
            @FormParam("country") String country) {

        if (name == null || name.trim().isEmpty()) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity("{\"error\": \"Name is required\"}")
                    .build();
        }

        if (email == null || email.trim().isEmpty()) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity("{\"error\": \"Email is required\"}")
                    .build();
        }

        EntityManager em = HibernateUtil.getEntityManager();

        try {
            em.getTransaction().begin();

            Customer customer = new Customer(name.trim(), email.trim(),
                    country != null ? country.trim() : null);
            em.persist(customer);

            em.getTransaction().commit();

            return Response.status(Response.Status.CREATED)
                    .entity(customer)
                    .build();

        } catch (Exception e) {
            if (em.getTransaction().isActive()) {
                em.getTransaction().rollback();
            }
            e.printStackTrace();
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("{\"error\": \"Failed to create customer: " + e.getMessage() + "\"}")
                    .build();
        } finally {
            em.close();
        }
    }

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Response listCustomers() {
        EntityManager em = HibernateUtil.getEntityManager();

        try {
            var customers = em.createQuery("SELECT c FROM Customer c", Customer.class)
                    .getResultList();

            return Response.ok(customers).build();

        } catch (Exception e) {
            e.printStackTrace();
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("{\"error\": \"Failed to fetch customers: " + e.getMessage() + "\"}")
                    .build();
        } finally {
            em.close();
        }
    }
}
