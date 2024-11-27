import { FastifyInstance } from 'fastify';
import sensible from '@fastify/sensible';
import { helloHandler } from '../handlers/handlers';

export default async function (fastify: FastifyInstance) {
  fastify.register(sensible);

  fastify.route({
    method: 'GET',
    url: '/',
    handler: async function () {
      fastify.log.info('GET / route hit');
      return { root: true };
    },
  });

  // This route calls a test handler that throws an error
  // to test the error handling functionality of the sensible plugin
  fastify.route({
    method: 'GET',
    url: '/error',
    handler: async function () {
      throw new Error('Test error');
    },
  });

  // New route with handler
  fastify.route({
    method: 'GET',
    url: '/hello',
    handler: helloHandler,
  });
}
