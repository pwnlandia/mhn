import { hashSync } from 'bcrypt'

const saltRounds = 10
export function hashPassword(password: string): string {
    return hashSync(password, saltRounds)
}
