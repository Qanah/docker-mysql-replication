require('elastic-apm-node').start({
    serviceName: 'node-app',
    serverUrl: process.env.ELASTIC_APM_SERVER_URL,
})

const express = require('express')
const app = express()

app.get('/', (req, res) => {
    res.send('Node APM active')
})

app.listen(3000, () => console.log('Node app listening on port 3000'))