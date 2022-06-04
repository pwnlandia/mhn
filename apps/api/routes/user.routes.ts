import {
    RawReplyDefaultExpression,
    RawRequestDefaultExpression,
    RawServerDefault,
    RouteOptions,
} from 'fastify'
import {
    CreateUserQueryType,
    userOutputType,
    userType,
} from '../schemas/user.type'
import { createUser } from '../controllers/user'

const create: RouteOptions<
    RawServerDefault,
    RawRequestDefaultExpression,
    RawReplyDefaultExpression,
    CreateUserQueryType
> = {
    method: 'POST',
    url: '/api/user',
    schema: {
        body: userType,
        response: {
            201: userOutputType, // Trims out password field.
        },
    },
    handler: createUser,
}

const userRoutes = [create]
export default userRoutes
