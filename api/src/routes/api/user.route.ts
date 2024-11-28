import { FastifyInstance } from 'fastify';
import {
  createUserHandler,
  getUsersHandler,
} from '../../handlers/user.handler';
import { createUserSchema } from '../../types/user.types';

export default async function userRoutes(fastify: FastifyInstance) {
  fastify.route({
    method: 'GET',
    url: '/user',
    handler: getUsersHandler,
  });

  fastify.route({
    method: 'POST',
    url: '/user',
    schema: createUserSchema,
    handler: createUserHandler,
  });
}
