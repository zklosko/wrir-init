// Note: this script only ingests MP3s. OGG files may be added later.
// Test: node lib/ingest.js -l shows -f "/Users/zacharyklosko/Desktop/WRIRtest/raw"

const fs = require('fs');
const path = require('path');
require('dotenv').config();
const { program } = require('commander');
const NodeID3 = require('node-id3');

const dayjs = require('dayjs');
var customParseFormat = require('dayjs/plugin/customParseFormat')
dayjs.extend(customParseFormat)

const { PrismaClient } = require('@prisma/client')
const prisma = new PrismaClient();

const objStorURL = process.env.MINIO_URL
const Minio = require('minio');
const minioClient = new Minio.Client({
    endPoint: objStorURL,
    port: 9000,
    useSSL: false,
    accessKey: process.env.MINIO_ACCESS_KEY,
    secretKey: process.env.MINIO_SECRET_KEY
});

function uploadMedia(bucket, filename, filepath) {
    minioClient.fPutObject(bucket, filename, filepath, function (err, etag) {
        if (err)
            return console.log(err);
        console.log('File ' + filename + ' uploaded successfully');
    });
}

program
    .version('0.0.1')
    .option('-l, --library <type>', 'kind of media to import (music, shows)')
    .option('-f, --filepath <type>', 'directory to import')

program.parse();
const dirPath = program.opts().filepath
const progMode = program.opts().library
if (!program.opts().filepath || !program.opts().library || (program.opts().library != 'music' && program.opts().library != 'shows') ) { process.exit(1) }


function getAllFiles(dirPath, filesArray) {
    // dirPath: str, filesArray: array
    files = fs.readdirSync(dirPath);

    filesArray = filesArray || [];

    files.forEach(function (file) {
        if (fs.statSync(dirPath + "/" + file).isDirectory()) {
            filesArray = getAllFiles(dirPath + "/" + file, filesArray);
        } else if (path.extname(file) === '.mp3') {
            // Is mp3
            console.log('Found showfile ' + file);
            filesArray.push(path.join(dirPath, "/", file));
        } else {
            // Is file but not mp3
            return;
        }
    });

    return filesArray;
}

const result = getAllFiles(dirPath)

result.forEach(async(file) => {
    try {
        let fileURL, filename, showWeekday, showData, urlPrefix
        const tags = NodeID3.read(file)

        urlPrefix = minioClient.protocol + '//' + objStorURL + ':' + minioClient.port + '/'
        
        if (progMode === 'music') {
            // need to find way to get filepath with extension without directories (as seen on server)
            filename = tags.artist.replace(/ /g, "_") + '/' + tags.title.replace(/ /g, "_") + '.mp3'
            uploadMedia('livemusic', filename, file)

            // maybe use https://serverurl.com:port/livemusic/year/artist/track for fileurl
            fileURL =  urlPrefix + 'livemusic/' + filename
            await prisma.livemusic.create({
                data: {
                    title: tags.title,
                    artist: tags.artist,
                    show: tags.album,
                    date: tags.year,
                    filetime: dayjs(fs.statSync(file).ctime).format(),
                    genre: tags.genre,
                    trackno: tags.trackNumber,
                    fpath: fileURL,
                }
            });        

        } else if (progMode === 'shows') {
            let filenameArray = file.split("/")
            filename = filenameArray[filenameArray.length - 1]  // get last part

            showWeekday = dayjs(filename.slice(0,9), "YYYYMMDD").format("dddd")

            showData = await prisma.schedule.findUnique({
                where: {
                    showID: {
                        weekday: showWeekday,
                        startTime: parseInt(filename.slice(8,12), 10),  // pulls show time from filename
                    }
                },    
            })
            uploadMedia('shows', filename, file)

            await prisma.shows.create({
                data: {
                    title: showData.showNameFormal,
                    show: showData.showName,
                    datestamp: filename.slice(0,12),
                    dateunix: dayjs(filename.slice(0,12), "YYYYMMDDhhmm").format(),
                    mp3: urlPrefix + 'shows/' + filename,
                    // ogg: ...,
                    type: showData.type,
                    showurl: showData.showURL,
                    poster: showData.showIcon
                }
            })
        }
    } catch (err) { console.log(err) }
})
