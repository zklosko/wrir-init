const express = require("express")
const hbs = require("express-handlebars")
const _ = require("underscore")
const { cleaner } = require('lib/cleaner')

const { PrismaClient } = require('@prisma/client')
const prisma = new PrismaClient()

const app = new express()

app.engine('hbs', hbs.engine({defaultLayout: 'main', extname: '.hbs'}))
app.set('view engine', 'hbs')
app.use(express.json())

// Routes start here
app.get('/', async (req, res) => {
    const showlist = await prisma.shows.findMany()
    res.render('index', { show: showlist })
})

app.get('/showlist', async (req, res) => {
    const showlist = await prisma.shows.findMany()
    res.json(showlist)
})

app.post('/cleanup/:days', async (req, res) => {
    const deletionDays = parseInt(req.query.days, 10);
    cleaner(deletionDays)

    res.json({"shows": "cleaned up", "days deleted": deletionDays})
})

/////////

app.get('/livesound', async (req, res) => {
    const showlist = await prisma.livemusic.findMany()
    res.json(showlist)
})

app.get('/livebands', async (req, res) => {
    const bandlist = await prisma.livemusic.findMany({
        distinct: ['artist'],
        select: {
            artist: true
        }
    })
    res.json(bandlist)
})

app.get('/livegenre', async (req, res) => {
    const genrelist = await prisma.livemusic.findMany({
        distinct: ['genre'],
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
