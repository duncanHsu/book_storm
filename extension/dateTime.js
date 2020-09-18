const sevendayToInt = {'Mon':1,'Tues':2,'Wed':3,'Thurs':4,'Fri':5,'Sat':6,'Sun':7,};
const sevendayToString = [ "",'Mon','Tues','Wed','Thurs','Fri','Sat','Sun'];

const dateConvert = (timeString, ampm) => {
    let h = 0;
    let m = 0;
    
    if(timeString.indexOf(':') > 0) {
        let sp = timeString.split(':');
        h = parseInt(sp[0]);
        m = parseInt(sp[1]);
    }
    else {
        h = parseInt(timeString);
    }

    h = h + (ampm == 'pm' ? 12 : 0);

    return new Date(0, 0, 0, h, m, 0);
}

const dateToDouble = (timeString, ampm, cross) => {
    let dateTime = 0.0;
    if (timeString.indexOf(':') > 0) {
        let sp = timeString.split(':');
        dateTime = parseInt(sp[0]);
        dateTime += parseInt(sp[1]) / 60;
    }
    else {
        dateTime = parseInt(timeString);
    }

    if (cross) {
        dateTime += 24;
    }

    dateTime = dateTime + (ampm == 'pm' ? 12 : 0);

    return dateTime;
}

module.exports = {
    sevendayToInt,
    sevendayToString,
    dateConvert,
    dateToDouble
};