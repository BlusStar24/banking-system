    // transferworkflow.js
    const express = require('express');
    const router = express.Router();
    const bonita = require('./transferBonitaClient');
    const mysql = require('mysql2/promise'); 

    const pool = mysql.createPool({
        host: 'bank-registration-system-mysql-1', // ← dùng tên container
        port: 3306,
        user: 'root',
        password: 'root',
        database: 'bank_users'
    });


    /**
     * POST /transfer/start
     * Body: contract input trực tiếp cho start process
     */
    router.post('/transfer/start', async (req, res) => {
        try {
            await bonita.login();
            const processId = await bonita.getProcessIdByName();
            const started = await bonita.startProcess(processId, {}); // payload rỗng
            res.json({
                status: 'started',
                caseId: started.caseId,
                processInstance: started
            });
        } catch (e) {
            res.status(500).json({ error: e.message });
        }
    });


    /**
     * GET /transfer/task/open?caseId=...&name=...
     */
    router.get('/transfer/task/open', async (req, res) => {
        try {
            const { caseId, name } = req.query;
            if (!caseId || !name) return res.status(400).json({ error: 'Thiếu caseId hoặc name' });
            await bonita.login();
            const task = await bonita.findOpenTaskByName(caseId, name);
            res.json(task ? { ready: true, task } : { ready: false });
        } catch (e) {
            res.status(500).json({ error: e.message });
        }
    });

    /**
     * POST /transfer/submit-info
     * Body: { caseId, payload }
     * Gửi contract cho task "Nhap thong tin giao dich"
     */
    router.post('/transfer/submit-info', async (req, res) => {
        try {
            const { caseId, payload } = req.body;
            if (!caseId || !payload) return res.status(400).json({ error: 'Thiếu caseId hoặc payload' });
            const result = await bonita.executeTaskByName(caseId, 'Nhap thong tin giao dich', payload);
            res.json({ ok: true, ...result });
        } catch (e) {
            res.status(500).json({ error: e.message });
        }
    });

    /**
     * POST /transfer/task/execute
     * Body: { taskId?, caseId?, name?, payload, assignUserId? }
     */
    router.post('/transfer/task/execute', async (req, res) => {
        try {
            const { taskId, caseId, name, payload, assignUserId = 1 } = req.body;
            if (!payload) return res.status(400).json({ error: 'Thiếu payload' });
            await bonita.login();

            let task = null;
            if (taskId) {
                task = await bonita.getTaskById(taskId);
            } else if (caseId && name) {
                task = await bonita.findOpenTaskByName(caseId, name);
            }
            if (!task) return res.status(404).json({ error: 'Không tìm thấy task' });

            await bonita.assignTask(task.id, assignUserId);
            const execRes = await bonita.executeTask(task.id, payload);
            res.json({ ok: true, taskId: task.id, caseId: task.caseId, execRes });
        } catch (e) {
            res.status(500).json({ error: e.message });
        }
    });

    /**
     * POST /transfer/submit-pin
     * Body: { caseId, payload }
     * Gửi contract cho task "Nhap ma pin"
     */
    router.post('/transfer/submit-pin', async (req, res) => {
        try {
            const { caseId, payload } = req.body;
            if (!caseId || !payload)
                return res.status(400).json({ error: 'Thiếu caseId hoặc payload' });

            await bonita.login();
            const result = await bonita.executeTaskByName(caseId, 'Nhap ma pin', payload);
            res.json({ ok: true, ...result });
        } catch (e) {
            res.status(500).json({ error: e.message });
        }
    });

    /**
     * POST /transfer/submit-otp
     * Body: { caseId, payload }
     * Gửi contract cho task "Nhap otp"
     */
    router.post('/transfer/submit-otp', async (req, res) => {
        try {
            const { caseId, payload } = req.body;
            if (!caseId || !payload)
                return res.status(400).json({ error: 'Thiếu caseId hoặc payload' });

            await bonita.login();
            const result = await bonita.executeTaskByName(caseId, 'Nhap otp', payload);
            res.json({ ok: true, ...result });
        } catch (e) {
            res.status(500).json({ error: e.message });
        }
    });


    /**
     * POST /transfer/submit-otp
     * Body: { caseId, payload }
     * Gửi contract cho task "Nhập kết qua ngân hàng"
     */
    router.post('/transfer/submit-external', async (req, res) => {
        try {
            const { caseId, payload } = req.body;
            if (!caseId || !payload || !payload.clientRequestId_ct)
                return res.status(400).json({ error: 'Thiếu caseId hoặc clientRequestId_ct trong payload' });

            // Truy DB để lấy transaction_id từ clientRequestId
            const [rows] = await pool.query(
                `SELECT transaction_id FROM transactions WHERE client_request_id = ? ORDER BY created_at DESC LIMIT 1`,
                [payload.clientRequestId_ct]
            );

            if (rows.length === 0) {
                return res.status(404).json({ error: 'Không tìm thấy giao dịch với clientRequestId đã cung cấp' });
            }

            // Gán transactionId vào payload
            payload.transactionId_ct = rows[0].transaction_id;

            // Gọi Bonita thực hiện task
            await bonita.login();
            const result = await bonita.executeTaskByName(caseId, 'Ket qua ngan hang', payload);

            res.json({ ok: true, transactionId: rows[0].transaction_id, ...result });
        } catch (e) {
            console.error(e);
            res.status(500).json({ error: e.message });
        }
    });

    module.exports = router;
