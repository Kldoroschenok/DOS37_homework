const http = require('http');
const os = require('os');
const childProcess = require('child_process');

const getNodeVersion = () => {
    return childProcess.execSync('node -v').toString().trim();
};

const getOSVersion = () => {
    return os.type() + ' ' + os.release();
};

const server = http.createServer((req, res) => {
    const nodeVersion = getNodeVersion();
    const osVersion = getOSVersion();

    res.writeHead(200, {'Content-Type': 'text/plain'});
    res.end(`Версия Node.js: ${nodeVersion}\nВерсия ОС: ${osVersion}`);
});

server.listen(3000, () => {
    console.log('Сервер запущен на порту 3000');
});
