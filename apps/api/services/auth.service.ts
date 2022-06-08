import { hashSync, compareSync } from 'bcrypt'

import * as jwt from 'jwt-simple'

const secret = Buffer.from(
    'fe bb ee ab 66 46 95 86 d5 09 4a 07 92 0b 25 22 fe bb ee ab 66 46 95 86 d5 09 4a 07 92 0b 25 22',
    'hex'
).toString()

const saltRounds = 10
export function hashPassword(password: string): string {
    return hashSync(password, saltRounds)
}

export function passwordsMatch(data: string, encrypted: string): boolean {
    return compareSync(data, encrypted)
}

export function getJWT(username: string): string {
    const payload = { username: username } // TODO: Add expiry
    return jwt.encode(payload, secret) // TODO: Add refresh capabilities
}
