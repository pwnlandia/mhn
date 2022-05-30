import { FastifyReply, FastifyRequest } from 'fastify'

interface IQuerystring {
    username: string
    password: string
}

interface IHeaders {
    'h-Custom': string
}

export const getIndex = async (
    request: FastifyRequest<{
        Querystring: IQuerystring
        Headers: IHeaders
    }>,
    reply: FastifyReply
) => {
    const { username, password } = request.query
    const customHeader = request.headers['h-Custom']
    // do something with request data

    return (
        'logged in as ' +
        username +
        ' with ' +
        password +
        ' and header ' +
        customHeader
    )
}
