import {
    RawReplyDefaultExpression,
    RawRequestDefaultExpression,
    RawServerDefault,
    RouteOptions,
} from 'fastify'
import { CreateUserQueryType, userType } from '../schemas/user.type'
import { createUser } from '../controllers/user'

const create: RouteOptions<
    RawServerDefault,
    RawRequestDefaultExpression,
    RawReplyDefaultExpression,
    CreateUserQueryType
> = {
    method: 'POST',
    url: '/user',
    schema: {
        body: userType,
    },
    handler: createUser,
}

const userRoutes = [create]
export default userRoutes
