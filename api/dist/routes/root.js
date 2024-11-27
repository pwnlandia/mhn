"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.default = default_1;
const sensible_1 = __importDefault(require("@fastify/sensible"));
const handlers_1 = require("../handlers/handlers");
async function default_1(fastify) {
    fastify.register(sensible_1.default);
    fastify.route({
        method: 'GET',
        url: '/',
        handler: async function () {
            fastify.log.info('GET / route hit');
            return { root: true };
        },
    });
    // This route calls a test handler that throws an error
    // to test the error handling functionality of the sensible plugin
    fastify.route({
        method: 'GET',
        url: '/error',
        handler: async function () {
            throw new Error('Test error');
        },
    });
    // New route with handler
    fastify.route({
        method: 'GET',
        url: '/hello',
        handler: handlers_1.helloHandler,
    });
}
