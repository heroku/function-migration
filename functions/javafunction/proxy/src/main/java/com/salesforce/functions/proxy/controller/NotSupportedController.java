package com.salesforce.functions.proxy.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Not supported routes.
 */
@RestController
public class NotSupportedController {

    @RequestMapping("/")
    public ResponseEntity<String> handleNotSupportedRequest() {
        return ResponseEntity.status(403).build();
    }
}
