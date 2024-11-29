import { FastifyReply, FastifyRequest } from 'fastify';
import {
  getAllUserNames,
  createUser,
  UserExistsError,
} from '../services/user.service';
import { CreateUserBody } from '../types/user.types';
import { log } from 'console';

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
    if (error instanceof UserExistsError) {
      reply.conflict(error.message);
      return;
    }
    log(error);
    reply.status(500).send({ error: 'An error occurred' });
  }
}
