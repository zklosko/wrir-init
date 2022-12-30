const { PrismaClient } = require('@prisma/client')
const prisma = new PrismaClient();
const { minioClient } = require('./minioClient.js')

const dayjs = require('dayjs');
var customParseFormat = require('dayjs/plugin/customParseFormat')
dayjs.extend(customParseFormat)

const deleteOlderThan = 15  // days
const deletionDate = dayjs().subtract(deleteOlderThan, 'day').toISOString()

async function deleteShowFromDB(el) {
    await prisma.shows.delete({
        where: {
            dateunix: el.dateunix
        }
    })
}

async function cleaner(deletionDate) {
    let query = await prisma.$queryRaw`select mp3, dateunix from shows where dateunix < ${deletionDate}::timestamp;`

    query.forEach(el => {
        let filenameArray = el.mp3.split("/")
        let filename = filenameArray[filenameArray.length - 1]  // get last part
        
        minioClient.removeObject('wrirwebarchive', 'shows' + filename, (e) => {
            if (e) {return console.log('Unable to delete ' + filename + '\n' + e)}
            deleteShowFromDB(el)
        })

        console.log('Show removed: ' + filename + '\n')
    })
}

cleaner(deletionDate)
