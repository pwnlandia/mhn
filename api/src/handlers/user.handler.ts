import { FastifyReply, FastifyRequest } from 'fastify';
import { getAllUserNames, createUser } from '../services/user.service';
import { CreateUserBody } from '../types/user.types';

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
  request: FastifyRequest<{ Body: CreateUserBody }>,
  reply: FastifyReply,
) {
  try {
    const { name, email, password } = request.body;
    const user = await createUser(name, email, password);
    reply.status(201).send(user);
  } catch (error) {
    reply.status(500).send({ error: 'An error occurred' });
  }
}
