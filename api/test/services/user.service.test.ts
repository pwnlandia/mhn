// src/__tests__/user.service.test.ts
jest.mock('../../src/lib/prisma', () => ({
  prisma: jest.requireActual('jest-mock-extended').mockDeep(),
}));
jest.mock('bcrypt');

import {
  getAllUserNames,
  createUser,
  UserExistsError,
} from '../../src/services/user.service';
import bcrypt from 'bcrypt';
import { PrismaClient } from '@prisma/client';
import { DeepMockProxy } from 'jest-mock-extended';
import { prisma } from '../../src/lib/prisma';

describe('User Service', () => {
  let prismaMock: DeepMockProxy<PrismaClient>;

  beforeEach(() => {
    prismaMock = prisma as DeepMockProxy<PrismaClient>;
    jest.clearAllMocks();
  });

  describe('getAllUserNames', () => {
    it('should return all user names', async () => {
      const mockUsers = [
        {
          id: 1,
          name: 'user1',
          email: 'user1@example.com',
          password: 'password1',
        },
        {
          id: 2,
          name: 'user2',
          email: 'user2@example.com',
          password: 'password2',
        },
      ];

      prismaMock.user.findMany.mockResolvedValue(mockUsers);

      const result = await getAllUserNames();
      expect(result).toEqual(['user1', 'user2']);
      expect(prismaMock.user.findMany).toHaveBeenCalledWith({
        select: { name: true },
      });
    });
  });

  describe('createUser', () => {
    const mockUser = {
      id: 1,
      name: 'testuser',
      email: 'test@example.com',
      password: 'hashedPassword123',
    };

    it('should create a new user successfully', async () => {
      prismaMock.user.findFirst.mockResolvedValue(null);
      (bcrypt.hash as jest.Mock).mockResolvedValue('hashedPassword123');

      prismaMock.user.create.mockResolvedValue({
        ...mockUser,
      });

      const result = await createUser(
        mockUser.name,
        mockUser.email,
        'password123',
      );

      expect(result).toEqual({
        id: 1,
        name: mockUser.name,
        email: mockUser.email,
      });
      expect(result).not.toHaveProperty('password');
    });

    it('should throw UserExistsError if name exists', async () => {
      prismaMock.user.findFirst.mockResolvedValue({ ...mockUser });

      await expect(
        createUser(mockUser.name, 'new@example.com', 'password123'),
      ).rejects.toThrow(
        new UserExistsError('User with this name already exists'),
      );
    });

    it('should throw UserExistsError if email exists', async () => {
      prismaMock.user.findFirst.mockResolvedValue({
        ...mockUser,
      });

      await expect(
        createUser('newuser', mockUser.email, 'password123'),
      ).rejects.toThrow(
        new UserExistsError('User with this email already exists'),
      );
    });

    it('should hash password before saving', async () => {
      prismaMock.user.findFirst.mockResolvedValue(null);
      prismaMock.user.create.mockResolvedValue({
        ...mockUser,
      });

      await createUser(mockUser.name, mockUser.email, 'password123');

      expect(bcrypt.hash).toHaveBeenCalledWith('password123', 10);
    });
  });
});
