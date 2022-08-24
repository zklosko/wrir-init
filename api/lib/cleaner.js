const { PrismaClient } = require('@prisma/client')
const prisma = new PrismaClient();

const dayjs = require('dayjs');
var customParseFormat = require('dayjs/plugin/customParseFormat')
dayjs.extend(customParseFormat)

const objStorURL = env("MINIO_URL")
const Minio = require('minio');
const minioClient = new Minio.Client({
    endPoint: objStorURL,
    port: 9000,
    useSSL: false,
    accessKey: env("MINIO_ACCESS_KEY"),
    secretKey: env("MINIO_SECRET_KEY")
});

const deleteOlderThan = 90  // days
const deletionDate = parseInt(dayjs().subtract(deleteOlderThan, 'day').format('YYYYMMDD'))

async function getDeletionList(deletionDate) {
    let list = await prisma.shows.findMany({
        where: {
            datestamp: {
                lte: deletionDate
            }
        },
        select: {
            datestamp: true,
            showName: true
        }
    });

    return list;
}

let deletionList = getDeletionList(deletionDate)

deletionList.forEach(async(el) => {
    let fileName = toString(el.datestamp) + el.showName + '.mp3'

    minioClient.removeObject('shows', fileName, (e) => {
        if (e) {
            console.log('Unable to delete ' + e)
        } else {
            // todo: delete from database
            await prisma.shows.delete({
                where: {
                    datestamp: el.datestamp,
                    showName: el.showName
                }
            })
        }
    })
    
})

console.log('Done! Files removed: \n')
deletionList.forEach(el => {
    console.log(el + '\n')
});
console.log('==================')