require('dotenv').config();
const { PrismaClient } = require('@prisma/client')
const prisma = new PrismaClient();

const dayjs = require('dayjs');
var customParseFormat = require('dayjs/plugin/customParseFormat')
dayjs.extend(customParseFormat)

const objStorURL = process.env.MINIO_URL
const Minio = require('minio');
const minioClient = new Minio.Client({
    endPoint: objStorURL,
    port: 9000,
    useSSL: false,
    accessKey: process.env.MINIO_ACCESS_KEY,
    secretKey: process.env.MINIO_SECRET_KEY
});

const deleteOlderThan = 30  // days
const deletionDate = dayjs().subtract(deleteOlderThan, 'day').toISOString()

async function deleteShowFromDB(el) {
    await prisma.shows.delete({
        where: {
            dateunix: el.dateunix
        }
    })
}

async function main(deletionDate) {
    let list = await prisma.$queryRaw`select mp3, dateunix from shows where dateunix < ${deletionDate}::timestamp;`

    list.forEach(el => {
        let filenameArray = el.mp3.split("/")
        let filename = filenameArray[filenameArray.length - 1]  // get last part
        
        try {
            minioClient.removeObject('shows', filename, (e) => {
                if (e) {
                    console.log('Unable to delete ' + e)
                } else {
                    deleteShowFromDB(el)
                }
            })
        } catch(err) {
            console.error(error)
        } finally {
            console.log('Show removed: ' + filename + '\n')
        }
    })
}

main(deletionDate)
