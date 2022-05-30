import fastify from "fastify";

interface IQuerystring {
  username: string;
  password: string;
}

interface IHeaders {
  "h-Custom": string;
}

const server = fastify();

server.get<{
  Querystring: IQuerystring;
  Headers: IHeaders;
}>(
  "/auth",
  {
    preValidation: (request, _reply, done) => {
      const { username } = request.query;
      done(username !== "admin" ? new Error("Must be admin") : undefined); // only validate `admin` account
    },
  },
  async (request, _reply) => {
    const { username, password } = request.query;
    const customHeader = request.headers["h-Custom"];
    // do something with request data

    return (
      "logged in as " +
      username +
      " with " +
      password +
      " and header " +
      customHeader
    );
  }
);

server.get("/ping", async (_request, _reply) => {
  return "pong\n";
});

server.listen(8080, (err, address) => {
  if (err) {
    console.error(err);
    process.exit(1);
  }
  console.log(`Server listening at ${address}`);
});
