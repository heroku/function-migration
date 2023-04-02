import Fastify from 'fastify'
import { ProxyServer } from './lib/proxy.js';

const fastify = Fastify({
    logger: true
});

const proxy = new ProxyServer(fastify);
try {
    proxy.validate();
} catch(err) {
    fastify.log.error(err.message);
    process.exit(1);
}

proxy.configure().startFunctionServer().start();