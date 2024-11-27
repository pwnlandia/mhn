import { FastifyReply, FastifyRequest } from 'fastify';
import { getAllUserNames } from '../services/user.service';
import { createUser } from '../services/user.service';

export async function getUsersHandler(
  request: FastifyRequest,
  reply: FastifyReply,
) {
  try {
    reply.send(await getAllUserNames());
  } catch (error) {
    reply.status(500).send({ error: 'An error occurred' });
  }
}
export async function createUserHandler(
  request: FastifyRequest,
  reply: FastifyReply,
) {
  try {
    const user = await createUser();
    reply.status(201).send(user);
  } catch (error) {
    reply.status(500).send({ error: 'An error occurred' });
  }
}
