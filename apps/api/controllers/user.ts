import { Prisma } from '@prisma/client'
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

    try {
        const user = await create({
            username: username,
            email: email,
            password: password,
        })
        reply.statusCode = 201
        reply.send(user)
    } catch (e) {
        if (e instanceof Prisma.PrismaClientKnownRequestError) {
            // There is a unique constraint violation, a new user cannot be created with this username
            if (e.code === 'P2002') {
                reply.statusCode = 409 // Conflict
                reply.send('Username already in use')
            }
        }
        throw e
    }
}
