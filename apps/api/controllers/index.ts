import { FastifyReply, FastifyRequest } from 'fastify'
import { UserType } from '../schemas/user.type'

export const getIndex = async (
    request: FastifyRequest<{
        Querystring: UserType
    }>,
    reply: FastifyReply
) => {
    const { username, password } = request.query
    const customHeader = request.headers['h-Custom']
    // do something with request data

    reply.send({
        hello:
            'logged in as ' +
            username +
            ' with ' +
            password +
            ' and footer ' +
            customHeader,
    })
}
