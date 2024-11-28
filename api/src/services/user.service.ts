import { prisma } from '../lib/prisma';
import bcrypt from 'bcrypt';

const SALT_ROUNDS = 10; // Industry standard

export async function getAllUserNames() {
  const users = await prisma.user.findMany({
    select: {
      name: true,
    },
  });
  return users.map((user) => user.name);
}

// TODO: Consider using typebox for validation and creating different types for request and response (ie. userWIthoutPassword).
export async function createUser(
  name: string,
  email: string,
  password: string,
) {
  // Hash password before storing
  const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);

  const user = await prisma.user.create({
    data: {
      name,
      email,
      password: hashedPassword,
    },
  });

  // Don't return password in response
  const { password: _, ...userWithoutPassword } = user;
  return userWithoutPassword;
}

// For login verification
export async function verifyPassword(
  plainPassword: string,
  hashedPassword: string,
): Promise<boolean> {
  return bcrypt.compare(plainPassword, hashedPassword);
}
