package com.salesforce.functions.proxy.handler;

import com.salesforce.functions.proxy.config.ProxyConfig;
import com.salesforce.functions.proxy.util.Utils;
import org.springframework.beans.factory.annotation.Autowired;

public abstract class BaseHandler implements Handler {

    @Autowired
    ProxyConfig proxyConfig;

    @Autowired
    Utils utils;
}
