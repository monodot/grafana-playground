package com.example.customer;

public class PlatformFaultException extends RuntimeException {

    public PlatformFaultException(String message, Throwable cause) {
        super(message, cause);
    }
}
