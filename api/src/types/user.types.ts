// src/types/user.types.ts
export interface CreateUserBody {
  name: string;
  email: string;
  password: string;
}

export const createUserSchema = {
  body: {
    type: 'object',
    required: ['name', 'email', 'password'],
    properties: {
      name: {
        type: 'string',
        minLength: 3,
        pattern: '^[a-zA-Z0-9_]+$', // Only alphanumeric and underscore
      },
      email: { type: 'string', format: 'email' },
      password: { type: 'string', minLength: 6 },
    },
  },
} as const;
