import { FastifyInstance, FastifyPluginOptions } from 'fastify';
import path from 'node:path';
import AutoLoad from '@fastify/autoload';
import { LoggerOptions } from 'pino';

interface EnvToLogger {
  [key: string]: LoggerOptions | boolean;
}

// Pass --options via CLI arguments in command to enable these options.
const options: FastifyPluginOptions = {};

export default async function (
  fastify: FastifyInstance,
  opts: FastifyPluginOptions,
) {
  // Do not touch the following lines

  // This loads all plugins defined in plugins
  // those should be support plugins that are reused
  // through your application
  fastify.register(AutoLoad, {
    dir: path.join(__dirname, 'plugins'),
    options: Object.assign({}, opts),
  });

  // This loads all plugins defined in routes
  // define your routes in one of these
  fastify.register(AutoLoad, {
    dir: path.join(__dirname, 'routes'),
    options: Object.assign({}, opts),
  });
}

module.exports.options = options;

// Start the Fastify server
const start = async () => {
  const envToLogger: EnvToLogger = {
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
      fastify.listen({ port: 3000 }, (err: Error, address: string) => {
        if (err) {
          fastify.log.error(err);
          process.exit(1);
        }
        fastify.log.info(`Server listening on ${address}`);
      });
    });
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();
