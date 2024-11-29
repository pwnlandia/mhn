// test/root.test.ts
import Fastify, { FastifyInstance } from 'fastify';
import sensible from '@fastify/sensible';
import rootRoutes from '../../src/routes/index';

describe('Root Routes', () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    app = Fastify();
    app.register(sensible);
    app.register(rootRoutes);
    await app.ready();
  });

  afterAll(() => {
    app.close();
  });

  test('GET / should return { root: true }', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/',
    });
    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual({ root: true });
  });

  test('GET /error should throw an error', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/error',
    });
    expect(response.statusCode).toBe(500);
    expect(response.json()).toEqual({
      error: 'Internal Server Error',
      message: 'Test error',
      statusCode: 500,
    });
  });

  test('GET /hello should return { message: "Hello, world!" }', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/hello',
    });
    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual({ message: 'Hello, world!' });
  });
});
