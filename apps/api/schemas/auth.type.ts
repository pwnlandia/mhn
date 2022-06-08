import { Static, Type } from '@sinclair/typebox'

export const authHeaderType = Type.Object({
    Authorization: Type.String(),
})

export type AuthHeaderType = Static<typeof authHeaderType>

export const authInterfaceType = Type.Object({
    Headers: authHeaderType,
})

export type AuthInterfaceType = Static<typeof authInterfaceType>
