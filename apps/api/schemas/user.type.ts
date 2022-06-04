import { Static, Type } from '@sinclair/typebox'

export const userType = Type.Object({
    username: Type.String(),
    email: Type.Optional(Type.String({ format: 'email' })),
    password: Type.String(),
})

export type UserType = Static<typeof userType>

export const userOutputType = Type.Object({
    username: Type.String(),
    email: Type.Optional(Type.String({ format: 'email' })),
})

export type UserOutputType = Static<typeof userOutputType>

export const userQueryType = Type.Object({
    Querystring: userType,
})

export type UserQueryType = Static<typeof userQueryType>

export const createUserQueryType = Type.Object({
    Body: userType,
})

export type CreateUserQueryType = Static<typeof createUserQueryType>
