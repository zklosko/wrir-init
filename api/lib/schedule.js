const csvParser = require("csv-parser");
const needle = require("needle");

const { PrismaClient } = require('@prisma/client')
const prisma = new PrismaClient();

// One line of schedule.csv
// Monday|0100|BickeringSiblings|"Bickering Siblings"|music|bickeringsiblings|https://www.wrir.org/show/bickering-siblings/|https://www.wrir.org/wp-content/uploads/2021/10/IMG_2390-1-150x150.jpg|
// Fields:
// WeekDay | startHr | showname | Show Name Formal | cat (music, local, other) | djusername | show url | show logo img

const result = [];

const checkIfCurrent = async function(showObj) {
    // query will be empty array if nothing found
    const query = await prisma.schedule.findUnique({
        where: {
            showID: {
                weekday: showObj.weekday,
                startTime: parseInt(showObj.startTime),
            }
        },
    })

    // incoming show has unique timeslot
    if (!query) {
        // add to database
        await prisma.schedule.create({
            data: {
                weekday: showObj.weekday,
                startTime: parseInt(showObj.startTime),
                showName: showObj.showName,
                showNameFormal: showObj.showNameFormal,
                type: showObj.type,
                dj: showObj.dj,
                showURL: showObj.showURL,
                showIcon: showObj.showIcon,
                showIcon2: showObj.showIcon2,
            }
        })    

    // incoming show replaces old show's timeslot
    } else {
        await prisma.schedule.update({
            where: {
                showID: {
                    weekday: showObj.weekday,
                    startTime: parseInt(showObj.startTime, 10),
                }     
            },
            data: {
                weekday: showObj.weekday,
                startTime: parseInt(showObj.startTime),
                showName: showObj.showName,
                showNameFormal: showObj.showNameFormal,
                type: showObj.type,
                dj: showObj.dj,
                showURL: showObj.showURL,
                showIcon: showObj.showIcon,
                showIcon2: showObj.showIcon2
            }
        })
    }
}

needle
  .get("https://www.wrir.org/generate-schedule-csv")
  .pipe(csvParser({ 
    separator: '|',
    headers: ['weekday', 'startTime', 'showName', 'showNameFormal', 'type', 'dj', 'showURL', 'showIcon', 'showIcon2']
  }))
  .on("data", (data) => {
    result.push(data); // final object captured
    // checkIfCurrent(data)
  })
  .on("done", (err) => {
    if (err) console.log("An error has occurred");
    // else console.log(result);
    result.forEach(show => {
        checkIfCurrent(show)
        // console.log(show)
    });
  });
