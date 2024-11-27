import { FastifyInstance } from 'fastify';
import { createUserHandler, getUsersHandler } from '../handlers/user.handler';

export default async function userRoutes(fastify: FastifyInstance) {
  fastify.route({
    method: 'GET',
    url: '/user',
    handler: getUsersHandler,
  });
  fastify.route({
    method: 'POST',
    url: '/user',
    handler: createUserHandler,
  });
}
