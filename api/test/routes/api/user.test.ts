// test/api/user.test.ts
import Fastify, { FastifyInstance } from 'fastify';
import sensible from '@fastify/sensible';
import rootRoutes from '../../../src/routes';
import errorHandler from '../../../src/plugins/errorHandler';

describe('User API Routes', () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    app = Fastify();
    await app.register(sensible);

    // Register routes with API prefix and error handler
    await app.register(
      async (fastify) => {
        await fastify.register(errorHandler);
        await fastify.register(rootRoutes);
      },
      { prefix: '/api' },
    );

    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  describe('POST /api/user', () => {
    const validUser = {
      name: 'john_doe',
      email: 'john@example.com',
      password: 'password123',
    };

    // TODO: Add test for valid user creation

    test('should reject user with conflicting name', async () => {
      // Try to create another user with the same name
      const response = await app.inject({
        method: 'POST',
        url: '/api/user',
        payload: validUser,
      });

      expect(response.statusCode).toBe(409);
      expect(response.json()).toMatchObject({
        error: 'User with this name already exists',
      });
    });

    test('should reject invalid name format', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/user',
        payload: {
          ...validUser,
          name: 'invalid@name',
        },
      });

      expect(response.statusCode).toBe(400);
      expect(response.json()).toMatchObject({
        error: 'Validation Error',
        details: expect.arrayContaining([
          expect.objectContaining({
            message: 'name must contain only letters, numbers, and underscores',
          }),
        ]),
      });
    });

    test('should reject missing required fields', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/user',
        payload: {},
      });

      expect(response.statusCode).toBe(400);
      expect(response.json()).toMatchObject({
        error: 'Validation Error',
        details: expect.arrayContaining([
          expect.objectContaining({
            message: 'name is required',
          }),
        ]),
      });
    });
  });

  describe('GET /api/user', () => {
    test('should return list of user names', async () => {
      const response = await app.inject({
        method: 'GET',
        url: '/api/user',
      });

      expect(response.statusCode).toBe(200);
      expect(Array.isArray(response.json())).toBe(true);
    });
  });
});
