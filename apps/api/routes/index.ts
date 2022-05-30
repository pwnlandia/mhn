import { RouteOptions } from 'fastify'
import * as indexController from '../controllers/index'

const getIndex: RouteOptions = {
    method: 'GET',
    url: '/',
    schema: {
        querystring: {
            username: { type: 'string' },
            password: { type: 'string' },
        },
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
