import { prisma } from '../lib/prisma';
import { faker } from '@faker-js/faker';

export async function getAllUserNames() {
  const users = await prisma.user.findMany({
    select: {
      name: true,
    },
  });
  return users.map((user) => user.name);
}
export async function createUser() {
  const user = await prisma.user.create({
    data: {
      name: faker.person.fullName(),
      email: faker.internet.email(),
      password: faker.internet.password(),
    },
  });
  return user;
}
