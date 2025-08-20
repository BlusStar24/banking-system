const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const cors = require('cors');

const app = express();

// Bật CORS cho frontend (để trình duyệt gửi & nhận cookie)
app.use(cors({
    origin: ["http://localhost:3000", "http://localhost:3001"],
    credentials: true
}));


// Proxy Bonita API
app.use('/bonita', createProxyMiddleware({
    target: 'http://host.docker.internal:8080',
    changeOrigin: true,
    pathRewrite: { '^/bonita': '/bonita' },
    onProxyRes: (proxyRes, req) => {
        const origin = req.headers.origin;
        if (["http://localhost:3000", "http://localhost:3001"].includes(origin)) {
            proxyRes.headers['Access-Control-Allow-Origin'] = origin;
        }
        proxyRes.headers['Access-Control-Allow-Credentials'] = 'true';
        proxyRes.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS';
        proxyRes.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization';
    }
}));

app.listen(5050, () => {
    console.log('Proxy chạy tại http://localhost:5050');
});
