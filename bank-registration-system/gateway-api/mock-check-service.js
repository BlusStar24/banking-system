const express = require('express');
const app = express();
app.use(express.json());

// Dữ liệu danh sách
const blacklist = ["012345678912", "111111111111"];
const sanctionList = ["999999999999", "555555555555"];
const pepList = ["Nguyen Minister", "Tran PEP"];
const fraudEmails = ["fraud@fraud.com", "scammer@abc.com"];
const fraudPhones = ["999123456", "888888888"];

// 1. Blacklist
app.get('/api/blacklist', (req, res) => {
    res.json(blacklist);
});

// 2. Sanction
app.get('/api/sanction/check', (req, res) => {
    const { cccd } = req.query;
    res.json({
        sanctioned: sanctionList.includes(cccd),
        source: "SanctionList"
    });
});

// 3. PEP
app.get('/api/pep/check', (req, res) => {
    const { name } = req.query;
    const isPEP = pepList.some((pepName) => name.toLowerCase().includes(pepName.toLowerCase()));
    res.json({ pep: isPEP });
});

// 4. Credit
app.get('/api/credit/score', (req, res) => {
    const { cccd } = req.query;

    // Nếu bị blacklist/sanction → Reject luôn (không chấm điểm)
    if (blacklist.includes(cccd) || sanctionList.includes(cccd)) {
        return res.json({ score: 0 });
    }

    // Khởi tạo score
    let score = 700;

    // Ví dụ: CCCD kết thúc bằng số lẻ → thu nhập thấp (demo)
    if (parseInt(cccd.slice(-1)) % 2 !== 0) {
        score -= 150;
    }

    // Ví dụ: CCCD có số 99 → nợ quá hạn nhẹ (demo)
    if (cccd.includes("99")) {
        score -= 200;
    }

    // Ví dụ: CCCD có số 000 → chưa có lịch sử tín dụng (demo)
    if (cccd.includes("000")) {
        score -= 100;
    }

    // Giới hạn điểm tối thiểu
    if (score < 300) score = 300;

    res.json({ score });
});


// 5. Fraud detection
app.post('/api/fraud/check', (req, res) => {
    const { email, phone } = req.body;
    const isFraud = fraudEmails.includes(email) || fraudPhones.includes(phone);
    res.json({ fraud: isFraud });
});

const PORT = 6000;
app.listen(PORT, () => console.log(`Mock Check Service chạy tại http://localhost:${PORT}`));
