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

program
    .version('0.0.3')
    .requiredOption('-f, --filepath <type>', 'directory to import')
    .option('-s --single', 'upload single file')
    .option('-m --music', 'upload to performances archive (uploads to show archive by default)')

program.parse();
const options = program.opts()

const uploadMedia = (bucket, filename, filepath) => {
    minioClient.fPutObject(bucket, filename, filepath, function (err, etag) {
        if (err)
            return console.log(err);
        console.log('File ' + filename + ' uploaded successfully');
    });
}

const getAllFiles = (dirPath, filesArray) => {
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

const putShowInDB = async (showWeekday, filename, mp3) => {
    let showData = await prisma.schedule.findUnique({
        where: {
            showID: {
                weekday: showWeekday,
                startTime: parseInt(filename.slice(8,12), 10),  // pulls show time from filename
            }
        },    
    })
    let createShow = await prisma.shows.create({
        data: {
            title: showData.showNameFormal,
            show: showData.showName,
            datestamp: filename.slice(0,12),
            dateunix: dayjs(filename.slice(0,12), "YYYYMMDDhhmm").format(),
            mp3: mp3,
            // ogg: ...,
            type: showData.type,
            showurl: showData.showURL,
            poster: showData.showIcon
        }
    })
}

const putMusicInDB = async (tags, file, fpath) => {
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
    })
}

const main = () => {
    let result = []
    if (options.single) {
        result.push(options.filepath)
    } else {
        result = getAllFiles(options.filepath)
        console.log('\n')
    }

    let filename, showWeekday, urlPrefix
    urlPrefix = minioClient.protocol + '//' + objStorURL + ':' + minioClient.port + '/'

    if (options.music) {
        result.forEach((file) => {
            try {
                const tags = NodeID3.read(file)
                if (!tags.artist) { tags.artist = 'Unknown' }
                if (!tags.title) {tags.title = tags.trackNumber}
                filename = tags.artist.replace(/ /g, "_") + '/' + tags.title.replace(/ /g, "_") + '.mp3'
                let fpath = urlPrefix + 'livemusic/' + filename // maybe use https://serverurl.com:port/livemusic/year/artist/track for fileurl
                
                putMusicInDB(tags, file, fpath)
                    .then(uploadMedia('livemusic', filename, file))    
            } catch (err) {
                console.log(err)
            }
        })
    } else {
        result.forEach((file) => {
            try {
                let filenameArray = file.split("/")
                filename = filenameArray[filenameArray.length - 1]  // get last part
        
                showWeekday = dayjs(filename.slice(0,9), "YYYYMMDD").format("dddd")
                let mp3 = urlPrefix + 'shows/' + filename

                putShowInDB(showWeekday, filename, mp3)
                    .then(uploadMedia('shows', filename, file))

            } catch (err) {
                console.log(err)
            }
        })
    }
}

main()
