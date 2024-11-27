"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const fastify_plugin_1 = __importDefault(require("fastify-plugin"));
const sensible_1 = __importDefault(require("@fastify/sensible"));
/**
 * This plugin adds some utilities to handle HTTP errors
 *
 * @see https://github.com/fastify/fastify-sensible
 */
exports.default = (0, fastify_plugin_1.default)(async function (fastify) {
    fastify.register(sensible_1.default);
});
