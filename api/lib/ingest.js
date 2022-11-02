// README: this script only ingests MP3s. OGG files may be added later.
// Test: node lib/ingest.js -l shows -f "/Users/zacharyklosko/Desktop/WRIRtest/raw"

const fs = require('fs');
const path = require('path');
const { parallelLimit } = require('async');
require('dotenv').config();
const { program } = require('commander');
const NodeID3 = require('node-id3');

const dayjs = require('dayjs');
let customParseFormat = require('dayjs/plugin/customParseFormat')
dayjs.extend(customParseFormat)

const { PrismaClient } = require('@prisma/client')
const prisma = new PrismaClient();

const objStorURL = process.env.MINIO_URL
const Minio = require('minio');
const minioClient = new Minio.Client({
    endPoint: objStorURL,
    port: 443,
    useSSL: true,
    accessKey: process.env.MINIO_ACCESS_KEY,
    secretKey: process.env.MINIO_SECRET_KEY
});
const urlPrefix = minioClient.protocol + '//' + 'wrirwebarchive' + '.' + objStorURL + '/';

program
    .version('0.0.3')
    .requiredOption('-f, --filepath <type>', 'directory to import')
    .option('-s --single', 'upload single file')
    .option('-m --music', 'upload to performances archive (uploads to show archive by default)')

program.parse();
const options = program.opts()

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

function uploadMusic(file, callback) {
    const tags = NodeID3.read(file);
    if (!tags.artist) { tags.artist = 'Unknown'; }
    if (!tags.title) { tags.title = tags.trackNumber; }
    let filename = tags.artist.replace(/ /g, "_") + '/' + tags.title.replace(/ /g, "_") + '.mp3';
    let fpath = urlPrefix + 'livemusic/' + filename; // maybe use https://serverurl.com:port/livemusic/year/artist/track for fileurl

    minioClient.fPutObject('wrirwebarchive', 'livemusic/' + filename, file, {'x-amz-acl': 'public-read'}, async function (err, etag) {
        if (err) {
            return console.log(err);
        } else {
            await prisma.livemusic.create({
                data: {
                    title: tags.title,
                    artist: tags.artist,
                    show: tags.album,
                    date: tags.year,
                    filetime: dayjs(fs.statSync(file).ctime).format(),
                    genre: tags.genre,
                    trackno: tags.trackNumber,
                    fpath: fpath
                }
            });
        }
        console.log('File ' + filename + ' uploaded successfully');
        callback()
    });
}

function uploadShow(file, callback) {
    let filenameArray = file.split("/");
    let filename = filenameArray[filenameArray.length - 1]; // get last part
    let mp3 = urlPrefix + 'shows/' + filename;

    minioClient.fPutObject('shows', filename, file, async function (err, etag) {
        if (err) {
            return console.log(err);
        } else {
            let showData = await prisma.schedule.findFirst({
                where: {
                    AND: {
                        weekday: {
                            equals: dayjs(filename.slice(0,9), "YYYYMMDD").format("dddd")
                        },
                        startTime: {
                            equals: filename.slice(8,12)
                        },
                        // showName: {
                        //     equals: // showName from file [13,infinity-extension]
                        // }
                    }
                }
            });
            let createShow = await prisma.shows.create({
                data: {
                    title: showData.showNameFormal,
                    show: showData.showName,
                    datestamp: filename.slice(0, 12),
                    dateunix: dayjs(filename.slice(0, 12), "YYYYMMDDhhmm").format(),
                    mp3: mp3,
                    // ogg: ...,
                    type: showData.type,
                    showurl: showData.showURL,
                    poster: showData.showIcon
                }
            });
        }
        console.log('File ' + filename + ' uploaded successfully');
        callback()
    });
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
            if (options.music) {
                uploadMusic(f, callback)
            } else {
                uploadShow(f, callback)
            }
        }
    })

    parallelLimit(tasks, 10, function() {
    });
}

main()
