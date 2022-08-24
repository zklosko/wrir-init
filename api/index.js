const express = require("express")
const hbs = require("express-handlebars")
const _ = require("underscore")

const { PrismaClient } = require('@prisma/client')
const prisma = new PrismaClient()

const app = new express()

app.engine('hbs', hbs.engine({defaultLayout: 'main', extname: '.hbs'}))
app.set('view engine', 'hbs')
app.use(express.json())

// Settings for Express's sendFile() function
// const sfOptions = {
//     maxAge: '1d',
//     headers: {
//         'Access-Control-Allow-Origin': '*',
//         'Content-Type': 'audio/mpeg',
//     },
// }

// Routes start here
app.get('/', async (req, res) => {
    const showlist = await prisma.shows.findMany()
    res.render('index', { show: showlist })
})

app.get('/showlist', async (req, res) => {
    const showlist = await prisma.shows.findMany()
    res.json(showlist)
})

// app.post('/addshow', async (req, res) => {
//     const addshow = await prisma.shows.create({
//         data: { ...req.body },
//     })
//     res.json(addshow)
// })

// app.get('/getshow', async (req, res) => {
//     const showid = parseInt(req.query.id)  // host/getshow?id=1 INT
//     const showquery = await prisma.shows.findUnique({
//         where: {
//             id: showid
//         },
//         select: {
//             mp3: true,
//             ogg: true
//         }
//     })
//     // Implement track return here
//     res.sendFile(showquery.mp3, sfOptions) // only works with filesystem
// })

/////////

app.get('/livesound', async (req, res) => {
    const showlist = await prisma.livemusic.findMany()
    res.json(showlist)
})

// app.post('/addlivesound', async (req, res) => {
//     const addlivesound = await prisma.livemusic.create({
//         data: { ...req.body },
//     })
//     res.json(addlivesound)
// })

app.get('/livebands', async (req, res) => {
    const bandlist = await prisma.livemusic.findMany({
        select: {
            artist: true
        }
    })
    res.json(_.chain(bandlist).uniq().sortBy().value())
})

app.get('/livegenre', async (req, res) => {
    const genrelist = await prisma.livemusic.findMany({
        select: {
            genre: true
        }
    })
    // Implement filtering for unique values
    let cleanGenrelist = []
    genrelist.forEach(element => {
        // Merge all objects into single array (showlist.genre)
        i = element.genre.split(";")  // Remove extra semicolons
        i.forEach(inner => {
            if (_.first(inner) === " "){
                cleanGenrelist.push(inner.substring(1))
            } else {
                cleanGenrelist.push(inner)
            }
        })
    })
    // Return array
    res.json(_.chain(cleanGenrelist).uniq().sortBy().value())
})

// app.get('/gettrack', async (req, res) => {
//     const trackid = parseInt(req.query.id) // host/gettrack?id=1 INT
//     const trackquery = await prisma.livemusic.findUnique({
//         where: {
//             id: trackid
//         },
//         select: {
//             fpath: true
//         }
//     })
//     // Implement track return here
//     // res.sendFile(trackquery.filepath, sfOptions)
//     res.redirect(302, trackquery.fpath)  // to serve from object storage
// })

// 404 handling
app.use((req, res, next) => {
    res.status(404);
    return res.json({
        success: false,
        message: `DEAD AIR: Endpoint not found for path: ${req.path}`
    })
})

// Server runtime
app.listen(3000, () => {
    console.log('REST API server ready at: http://localhost:3000 🚀')
})
