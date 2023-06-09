package com.salesforce.functions.proxy.service;

import org.springframework.stereotype.Service;

import java.io.IOException;

/**
 * Service that handles starting given ProcessBuilder.
 */
@Service
public class ProcessStartService {

    public ProcessHandle start(ProcessBuilder processBuilder) throws IOException {
        return processBuilder.inheritIO().start().toHandle();
    }
}
