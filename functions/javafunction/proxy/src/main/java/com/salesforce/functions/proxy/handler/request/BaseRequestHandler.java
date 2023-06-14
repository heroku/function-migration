package com.salesforce.functions.proxy.handler.request;

import com.salesforce.functions.proxy.config.ProxyConfig;
import com.salesforce.functions.proxy.util.Utils;
import org.springframework.beans.factory.annotation.Autowired;

abstract class BaseRequestHandler implements RequestHandler {

    @Autowired
    ProxyConfig proxyConfig;

    @Autowired
    Utils utils;
}
