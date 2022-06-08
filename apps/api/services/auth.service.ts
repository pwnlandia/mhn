import { hashSync, compareSync } from 'bcrypt'

const saltRounds = 10
export function hashPassword(password: string): string {
    return hashSync(password, saltRounds)
}

export function passwordsMatch(data: string, encrypted: string): boolean {
    return compareSync(data, encrypted)
}
