// README: this script only ingests MP3s. OGG files may be added later.
// Test: node lib/ingest.js -l shows -f "/Users/zacharyklosko/Desktop/WRIRtest/raw"

const fs = require('fs');
const path = require('path');
const { parallelLimit } = require('async');
require('dotenv').config();
const { program } = require('commander');
const { minioClient } = require('./minioClient.js')

const dayjs = require('dayjs');
let customParseFormat = require('dayjs/plugin/customParseFormat')
var utc = require('dayjs/plugin/utc')
var timezone = require('dayjs/plugin/timezone') // dependent on utc plugin
dayjs.extend(customParseFormat)
dayjs.extend(utc)
dayjs.extend(timezone)

const { PrismaClient } = require('@prisma/client')
const prisma = new PrismaClient();

program
    .version('0.1.0')
    .requiredOption('-f, --filepath <type>', 'directory to import')
    .option('-s --single', 'upload single file')

program.parse();
const options = program.opts()

const urlPrefix = 'https://wrirwebarchive.nyc3.digitaloceanspaces.com/';

function getAllFiles(dirPath, filesArray) {
    // dirPath: str, filesArray: array
    files = fs.readdirSync(dirPath);

    filesArray = filesArray || [];

    files.forEach(function (file) {
        if (fs.statSync(dirPath + "/" + file).isDirectory()) {
            filesArray = getAllFiles(dirPath + "/" + file, filesArray);
        } else if (path.extname(file) === '.mp3') {
            // Is mp3
            console.log(`Found showfile ${file}`);
            filesArray.push(path.join(dirPath, "/", file));
        } else {
            // Is file but not mp3
            return;
        }
    });

    return filesArray;
}

async function findShow(weekday, startTime, showName) {
    let query = await prisma.schedule.findUnique({
        where: {
            timeslot: weekday + startTime + showName
        }
    });
    return query
}

async function addShowToDB(showData, filename, mp3) {
    await prisma.shows.create({
        data: {
            title: showData.showNameFormal,
            show: showData.showName,
            datestamp: filename.slice(0, 12),
            dateunix: dayjs(filename.slice(0, 12), "YYYYMMDDhhmm").tz("America/New_York").format(),
            mp3: mp3,
            // ogg: ...,
            type: showData.type,
            showurl: showData.showURL,
            poster: showData.showIcon
        }
    });
}

async function uploadShow(file, callback) {
    let filenameArray = file.split("/");
    let filename = filenameArray[filenameArray.length - 1]; // get last part
    let mp3 = urlPrefix + 'shows/' + filename;

    let weekday = dayjs(filename.slice(0,9), "YYYYMMDD").format("dddd")
    let startTime = filename.slice(8,12)
    let showName = filename.split('.')[1]

    minioClient.fPutObject('wrirwebarchive', 'shows/' + filename, file, {'x-amz-acl': 'public-read'}, async (err, etag) => {
        if (err) {return console.log(err);}
        console.log(`File ${filename} uploaded successfully`);
        let showData
        try {
            showData = await findShow(weekday, startTime, showName)
        } catch (err) {
            return console.log(err)
        } finally {
            await addShowToDB(showData, filename, mp3)
        }
    });

    callback()
}

function main() {
    let files = [];
    if (options.single) {
        files.push(options.filepath);
    } else {
        files = getAllFiles(options.filepath);
        console.log('\n');
    }

    var tasks = files.map(function(f) {
        return function(callback) {
            uploadShow(f, callback)
        }
    })

    parallelLimit(tasks, 10, function() {
    });
}

main()
