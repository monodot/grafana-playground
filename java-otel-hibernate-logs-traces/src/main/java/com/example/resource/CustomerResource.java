package com.example.resource;

import com.example.entity.Customer;
import com.example.util.HibernateUtil;
import jakarta.persistence.EntityManager;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Path("/api/customers")
public class CustomerResource {

    private static final Logger logger = LoggerFactory.getLogger(CustomerResource.class);

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

            logger.info("Creating customer: name={}, email={}, country={}", name, email, country);
            em.persist(customer);

            em.getTransaction().commit();
            logger.info("Customer created successfully with id={}", customer.getId());

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

    @POST
    @Path("/bulk")
    @Consumes({MediaType.APPLICATION_JSON, MediaType.APPLICATION_FORM_URLENCODED})
    @Produces(MediaType.APPLICATION_JSON)
    public Response createBulkCustomers(@FormParam("count") Integer count) {
        if (count == null || count < 1) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity("{\"error\": \"Count must be at least 1\"}")
                    .build();
        }

        if (count > 100) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity("{\"error\": \"Count must not exceed 100\"}")
                    .build();
        }

        logger.info("Starting bulk customer creation: count={}", count);
        EntityManager em = HibernateUtil.getEntityManager();

        try {
            em.getTransaction().begin();

            var createdCustomers = new java.util.ArrayList<Customer>();

            for (int i = 1; i <= count; i++) {
                String name = "Customer " + i;
                String email = "customer" + i + "@example.com";
                String country = getRandomCountry(i);

                logger.debug("Creating customer {}/{}: name={}", i, count, name);
                Customer customer = new Customer(name, email, country);
                em.persist(customer);
                createdCustomers.add(customer);

                // Flush periodically to generate multiple SQL statements
                if (i % 10 == 0) {
                    logger.debug("Flushing batch at customer {}", i);
                    em.flush();
                }
            }

            em.getTransaction().commit();
            logger.info("Successfully created {} customers", createdCustomers.size());

            return Response.status(Response.Status.CREATED)
                    .entity(createdCustomers)
                    .build();

        } catch (Exception e) {
            if (em.getTransaction().isActive()) {
                em.getTransaction().rollback();
            }
            logger.error("Failed to create bulk customers", e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("{\"error\": \"Failed to create customers: " + e.getMessage() + "\"}")
                    .build();
        } finally {
            em.close();
        }
    }

    private String getRandomCountry(int index) {
        String[] countries = {"USA", "Canada", "UK", "Germany", "France", "Japan", "Australia", "Brazil", "India", "Mexico"};
        return countries[index % countries.length];
    }

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Response listCustomers() {
        logger.debug("Fetching all customers");
        EntityManager em = HibernateUtil.getEntityManager();

        try {
            var customers = em.createQuery("SELECT c FROM Customer c", Customer.class)
                    .getResultList();

            logger.info("Retrieved {} customers", customers.size());
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
