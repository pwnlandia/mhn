import { UserType } from '../schemas/user.type'
import { prisma } from '../client'
import { User } from '@prisma/client'
import { hashPassword } from './auth.service'

export const create = async (userInput: UserType): Promise<User> => {
    return prisma.user.create({
        data: {
            ...userInput,
            password: await hashPassword(userInput.password),
        },
    })
}

export const getByUsername = async (username: string): Promise<User | null> => {
    return prisma.user.findUnique({ where: { username: username } })
}
