import { Static, Type } from "@sinclair/typebox";

const User = Type.Object({
  username: Type.String(),
  email: Type.Optional(Type.String({ format: "email" })),
  password: Type.String(),
});

type UserType = Static<typeof User>;
