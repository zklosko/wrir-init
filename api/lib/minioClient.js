require('dotenv').config();
const Minio = require('minio');

const minioClient = new Minio.Client({
    endPoint: "nyc3.spaces.digitalocean.com",
    port: 443,
    useSSL: true,
    accessKey: process.env.SPACES_KEY,
    secretKey: process.env.SPACES_SECRET
});

export { minioClient }
