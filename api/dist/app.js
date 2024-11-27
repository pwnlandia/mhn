"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.default = default_1;
const node_path_1 = __importDefault(require("node:path"));
const autoload_1 = __importDefault(require("@fastify/autoload"));
// Pass --options via CLI arguments in command to enable these options.
const options = {};
async function default_1(fastify, opts) {
    // Do not touch the following lines
    // This loads all plugins defined in plugins
    // those should be support plugins that are reused
    // through your application
    fastify.register(autoload_1.default, {
        dir: node_path_1.default.join(__dirname, 'plugins'),
        options: Object.assign({}, opts),
    });
    // This loads all plugins defined in routes
    // define your routes in one of these
    fastify.register(autoload_1.default, {
        dir: node_path_1.default.join(__dirname, 'routes'),
        options: Object.assign({}, opts),
    });
}
module.exports.options = options;
// Start the Fastify server
const start = async () => {
    const envToLogger = {
        development: {
            transport: {
                target: 'pino-pretty',
                options: {
                    translateTime: 'HH:MM:ss Z',
                    ignore: 'pid,hostname',
                },
            },
        },
        production: true,
        test: false,
    };
    const fastify = require('fastify')({
        logger: envToLogger[process.env.NODE_ENV || 'development'],
    });
    try {
        await fastify.register(require('./app')).after(() => {
            fastify.listen({ port: 3000 }, (err, address) => {
                if (err) {
                    fastify.log.error(err);
                    process.exit(1);
                }
                fastify.log.info(`Server listening on ${address}`);
            });
        });
    }
    catch (err) {
        fastify.log.error(err);
        process.exit(1);
    }
};
start();
