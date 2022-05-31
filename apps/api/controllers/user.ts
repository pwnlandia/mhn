import { FastifyReply, FastifyRequest } from 'fastify'
import { UserType } from '../schemas/user.type'
import { create } from '../services/user.service'

export const createUser = async (
    request: FastifyRequest<{
        Body: UserType
    }>,
    reply: FastifyReply
) => {
    const { username, email, password } = request.body
    reply.statusCode = 201
    reply.send(
        await create({ username: username, email: email, password: password })
    )
}
