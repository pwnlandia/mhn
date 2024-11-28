// src/routes/index.ts
import { FastifyInstance } from 'fastify';
import userRoutes from './api/user.route';
import errorHandler from '../plugins/errorHandler';

export default async function apiRoutes(fastify: FastifyInstance) {
  await fastify.register(async (fastify) => {
    // Register error handler first within the same scope as routes
    await fastify.register(errorHandler);

    // Register routes in same scope as error handler
    await fastify.register(userRoutes);
    // Add more API route modules here
  });
}
