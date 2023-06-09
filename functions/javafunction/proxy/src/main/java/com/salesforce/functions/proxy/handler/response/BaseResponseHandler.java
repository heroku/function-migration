package com.salesforce.functions.proxy.handler.response;

import com.salesforce.functions.proxy.config.ProxyConfig;
import com.salesforce.functions.proxy.util.Utils;
import org.springframework.beans.factory.annotation.Autowired;

abstract class BaseResponseHandler implements ResponseHandler {

    @Autowired
    ProxyConfig proxyConfig;

    @Autowired
    Utils utils;
}
