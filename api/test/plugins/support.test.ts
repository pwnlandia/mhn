import Fastify, { FastifyInstance } from 'fastify';
import Support from '../../src/plugins/support';

describe('Support Plugin', () => {
  let fastify: FastifyInstance;

  beforeAll(async () => {
    fastify = Fastify();
    fastify.register(Support);
    await fastify.ready();
  });

  afterAll(() => {
    fastify.close();
  });

  test('support works standalone', () => {
    expect(fastify.someSupport()).toBe('hugs');
  });
});
