// README: Assumes shows being ingested are on current schedule. Does not check legacy schedules.

const axios = require("axios");
const { PrismaClient } = require('@prisma/client')
const prisma = new PrismaClient();
const dayjs = require('dayjs');
var utc = require('dayjs/plugin/utc')
var timezone = require('dayjs/plugin/timezone') // dependent on utc plugin
dayjs.extend(utc)
dayjs.extend(timezone)

async function getSchedule() {
  let data
  await axios.get('https://spinitron.com/api/shows?access-token=5oWyfhIJjmisHJIR_Rxn_sPA')
  .then((response) => {
    data = response.items
  },
  (error) => {
    console.log(error)
  })
  return data
}

async function queryByID(showID) {
  let show = await prisma.schedule.findUnique({
    where: {
      showID: showID
    }
  })
}

async function addToDB(show) {
  // build timeslot string here
  // enters like this  "start": "2023-01-13T18:00:00+0000",
  let timeslot = dayjs(show.start).format('dddHHmm').tz('America/New_York')
  try {
    await prisma.schedule.create({
      data: {
        showID: show.id,
        timeslot: timeslot,
        showName: show.title,
        category: show.category,
        url: show.url,
        icon: show.image
      }
    })
  } catch (err) {
    console.log(err)
  }
}

async function updateDB(show) {
  let timeslot = dayjs(show.start).format('dddHHmm').tz('America/New_York')
  await prisma.schedule.update({
    where: {
      showID: show.showID
    },
    data: {
      timeslot: timeslot,
      showName: show.title,
      category: show.category,
      url: show.url,
      icon: show.image
    }
  })
}

async function main() {
  let scheduleData = await getSchedule()
  console.log(scheduleData)
  scheduleData.forEach(element => {
    let showData = queryByID(element.showID)
    if (showData === null) {
      addToDB(element)
    } else {
      updateDB(element)
    }
  });
}

main()