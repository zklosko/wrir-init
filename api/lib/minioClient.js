// require('dotenv').config();
const Minio = require('minio');

const minioClient = new Minio.Client({
    endPoint: "nyc3.digitaloceanspaces.com",
    port: 443,
    useSSL: true,
    accessKey: "ADD SPACES KEY HERE",
    secretKey: "ADD SECRET KEY HERE"
});

module.exports = { minioClient }
