"use strict";
Object.defineProperty(exports, "__esModule", {
    value: true
});
Object.defineProperty(exports, "default", {
    enumerable: true,
    get: function() {
        return _default;
    }
});
const _config = require("@prisma/config");
const _default = (0, _config.defineConfig)({
    datasources: {
        db: {
            provider: 'mysql',
            url: process.env.DATABASE_URL ?? 'mysql://colmeia_user:colmeia_password@mysql:3306/colmeia_main'
        }
    }
});
