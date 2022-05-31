import {
    RawReplyDefaultExpression,
    RawRequestDefaultExpression,
    RawServerDefault,
    RouteOptions,
} from 'fastify'
import * as indexController from '../controllers/index'
import { UserQueryType, userType } from '../schemas/user.type'

const getIndex: RouteOptions<
    RawServerDefault,
    RawRequestDefaultExpression,
    RawReplyDefaultExpression,
    UserQueryType
> = {
    method: 'GET',
    url: '/',
    schema: {
        querystring: userType,
        response: {
            200: {
                type: 'object',
                properties: {
                    hello: { type: 'string' },
                },
            },
        },
    },
    handler: indexController.getIndex,
}

const indexRoutes = [getIndex]
export default indexRoutes
