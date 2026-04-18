var express = require('express')

const middleware = require('../middleware')
var router = express.Router()

module.exports = function () {
    router.use('/images', require('./images')())
    router.use('/files', require('./files')())
    router.use('/upload', require('./upload')());
    return router
}