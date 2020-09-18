const checkDuplicationNormal = (arr) => {
    return arr.some((val, idx) => {
        return arr.includes(val, idx + 1);
    });
}

module.exports = {
    checkDuplicationNormal
}
