const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const router = require('./transferworkflow');

const app = express();
app.use(cors());
app.use(bodyParser.json());
app.use('/', router);

app.listen(8081, () => {
    console.log('✅ Workflow API (Node.js) chạy tại http://localhost:8081');
});
