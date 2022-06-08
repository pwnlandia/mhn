import {
    RawReplyDefaultExpression,
    RawRequestDefaultExpression,
    RawServerDefault,
    RouteOptions,
} from 'fastify'
import { auth } from '../controllers/auth'

import { AuthInterfaceType } from '../schemas/auth.type'

const authenticate: RouteOptions<
    RawServerDefault,
    RawRequestDefaultExpression,
    RawReplyDefaultExpression,
    AuthInterfaceType
> = {
    method: 'POST',
    url: '/api/auth',
    handler: auth,
}

const authRoutes = [authenticate]
export default authRoutes
