"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const fastify_plugin_1 = __importDefault(require("fastify-plugin"));
// the use of fastify-plugin is required to be able
// to export the decorators to the outer scope
exports.default = (0, fastify_plugin_1.default)(async function (fastify) {
    fastify.decorate('someSupport', function () {
        return 'hugs';
    });
});
