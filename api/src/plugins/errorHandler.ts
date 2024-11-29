// src/plugins/errorHandler.ts
import {
  FastifyError,
  FastifyInstance,
  FastifyReply,
  FastifyRequest,
} from 'fastify';

function customErrorMessage(error: any): string {
  switch (error.keyword) {
    case 'required':
      return `${error.params.missingProperty} is required`;
    case 'pattern':
      return 'name must contain only letters, numbers, and underscores';
    case 'minLength':
      const propertyName = error.instancePath.split('/').pop();
      return `${propertyName} must be at least ${error.params.limit} characters`;
    case 'format':
      return 'must be a valid email address';
    default:
      return error.message;
  }
}

function errorHandler(fastify: FastifyInstance, opts: any, done: () => void) {
  // Log to verify plugin registration
  fastify.log.info('Registering custom error handler');

  fastify.setErrorHandler(function (
    error: FastifyError,
    request: FastifyRequest,
    reply: FastifyReply,
  ) {
    fastify.log.error(error);

    if (error.validation) {
      return reply.status(400).send({
        error: 'Validation Error',
        details: error.validation.map((err) => ({
          message: customErrorMessage(err),
        })),
      });
    }

    if (error.statusCode) {
      return reply.status(error.statusCode).send({ error: error.message });
    }
    return reply.status(500).send({ error: error.message });
  });

  done();
}

// Register as plugin with fastify-plugin to avoid encapsulation
import fp from 'fastify-plugin';
export default fp(errorHandler);
