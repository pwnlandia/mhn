import { FastifyReply, FastifyRequest } from 'fastify'
import { AuthInterfaceType } from '../schemas/auth.type'
import { passwordsMatch } from '../services/auth.service'
import * as userService from '../services/user.service'
import * as jwt from 'jwt-simple'

const secret = Buffer.from(
    'fe bb ee ab 66 46 95 86 d5 09 4a 07 92 0b 25 22',
    'hex'
).toString()

export const auth = async (
    request: FastifyRequest<AuthInterfaceType>,
    reply: FastifyReply
) => {
    const basicAuth = request.headers.authorization
    if (!basicAuth) {
        reply.statusCode = 400
        reply.send('poorly formed auth header')
        return
    }

    const headerParts = (<string>basicAuth).split(' ')
    if (headerParts[0] !== 'Basic') {
        reply.statusCode = 400
        reply.send('missing basic auth')
        return
    }
    const authString = Buffer.from(headerParts[1], 'base64').toString('binary') // The base64 encoded string of username:password
    const authParts = authString.split(':')
    const username = authParts[0]
    const password = authParts[1]

    const user = await userService.getByUsername(username)
    if (!user) {
        reply.statusCode = 401
        reply.send('unauthorized')
        return
    } else {
        if (!passwordsMatch(password, user.password)) {
            reply.statusCode = 401
            reply.send('unauthorized')
            return
        }
        // Authorized

        const payload = { username: username }
        const token = jwt.encode(payload, secret)
        reply.statusCode = 200
        reply.send(token)
        return
    }
}
