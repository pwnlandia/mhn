import fastify from 'fastify'
import indexRoutes from './routes'
import authRoutes from './routes/auth.routes'
import userRoutes from './routes/user.routes'

const server = fastify()

indexRoutes.forEach(function (route) {
    server.route(route)
})

userRoutes.forEach(function (route) {
    server.route(route)
})

authRoutes.forEach(function (route) {
    server.route(route)
})

server.get('/ping', async (_request, _reply) => {
    return 'pong\n'
})

server.listen(8080, (err, address) => {
    if (err) {
        console.error(err)
        process.exit(1)
    }
    console.log(`Server listening at ${address}`)
})
