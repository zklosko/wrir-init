const express = require("express")
const { PrismaClient } = require('@prisma/client')
const prisma = new PrismaClient()

const app = new express()

app.use(express.json())

// Routes start here
app.get('/', async (req, res) => {
    res.json({hi: 'WRIR!'})
})

app.get('/showlist', async (req, res) => {
    const showlist = await prisma.shows.findMany()
    res.json(showlist)
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
