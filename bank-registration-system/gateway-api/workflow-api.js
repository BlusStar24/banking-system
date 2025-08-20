const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const fetch = require('node-fetch'); // gọi OTP-service
const bonita = require('./bonitaClient');

const app = express();
app.use(cors({
    origin: ["http://localhost:3000", "http://localhost:3001"],
    credentials: true
}));

app.use(bodyParser.json());

/**
 * 1. Start process với accountDataInput (Contract Input COMPLEX)
 *    -> Gửi OTP qua OTP-service
 */
app.post('/workflow/account/start', async (req, res) => {
    try {
        console.log('Request body từ client:', JSON.stringify(req.body, null, 2));
        const { accountDataInput1 } = req.body;

        if (!accountDataInput1) {
            return res.status(400).json({ error: 'Thiếu accountDataInput1' });
        }

        // 1. Gọi user-service để tạo Customer trước
        const registerRes = await fetch('http://user-service:8080/api/customers/register', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(accountDataInput1)
        });

        const registerData = await registerRes.json();
        if (!registerRes.ok) {
            console.error('Lỗi register:', registerData);
            return res.status(400).json({
                error: 'Đăng ký customer thất bại',
                detail: registerData
            });
        }

        // 2. Gắn customerId trả về vào accountDataInput
        accountDataInput1.customerId = registerData.customer_id;
        console.log(`Đã tạo customerId: ${accountDataInput1.customerId}`);

        // 3. Start process Bonita (truyền accountDataInput có customerId)
        await bonita.login();
        const processId = await bonita.getProcessId('CreateAccountBank');
        const result = await bonita.startProcess(processId, { accountDataInput1 });

        console.log(
            `Bonita admin link: ${(process.env.BONITA_BASE_URL || 'http://localhost:25854/bonita')}/apps/adminAppBonita/admin-process-details/?id=${result.caseId}`
        );


        // 5. Trả về thông tin cho frontend
        res.json({
            status: 'started',
            caseId: result.caseId,
            customerId: accountDataInput1.customerId,
            processInstance: result
        });
    } catch (err) {
        console.error('Lỗi start process:', err.message);
        res.status(500).json({ error: err.message });
    }
});

/**
 * 2. Submit OTP task
 *    -> Verify OTP qua OTP-service trước
 *    -> Nếu hợp lệ thì gọi Bonita
 */
app.post('/workflow/account/otp', async (req, res) => {
    try {
        console.log('Request OTP:', JSON.stringify(req.body, null, 2));

        const { caseId, phone, email, otp } = req.body;
        if (!caseId || !phone || !email || !otp) {
            return res.status(400).json({
                error: 'Thiếu caseId, phone, email hoặc otp'
            });
        }

        // Gọi OTP-service verify
        const verifyRes = await fetch('http://otp-service:8080/api/otp/verify', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ phone, code: otp })
        });

        if (!verifyRes.ok) {
            return res.status(400).json({ error: 'OTP invalid or expired' });
        }

        // OTP hợp lệ => gọi Bonita
        await bonita.login();
        const task = await bonita.findTask(caseId, 'Khach Nhap OTP');
        if (!task) {
            return res.status(404).json({
                error: 'Không tìm thấy task OTP cho case này'
            });
        }

        await bonita.executeTask(task.id, {
            otpdataInput: {
                phone,
                email,
                otp
            }
        });

        res.json({ message: 'OTP đã được xác minh' });
    } catch (err) {
        console.error('Lỗi xác minh OTP:', err.message);
        res.status(500).json({ error: err.message });
    }
});

/**
 * 3. Check process status
 */
app.get('/workflow/account/status/:id', async (req, res) => {
    try {
        const caseId = req.params.id;
        console.log(`📥 Check status cho caseId: ${caseId}`);

        if (!caseId) {
            return res.status(400).json({ error: 'Thiếu caseId' });
        }

        await bonita.login();
        const status = await bonita.getCaseStatus(caseId);

        res.json(status);
    } catch (err) {
        console.error('Lỗi lấy trạng thái process:', err.message);
        res.status(500).json({ error: err.message });
    }
});

/**
 * 4. Kiểm tra trạng thái case để khóa/mở nút "Nhập số tài khoản"
 *  - approvalPending: còn task "Nhân viên phê duyệt" (chưa duyệt)  -> khóa nút + báo đợi
 *  - createAccountReady: task "Tạo số tài khoản" đã READY          -> mở nút
 *  - taskId: id của task "Tạo số tài khoản" nếu đã READY
 */
// GET /workflow/account/state/stream?caseId=1234
// Realtime state theo caseId
app.get('/workflow/account/state/stream', async (req, res) => {
    const { caseId } = req.query;
    if (!caseId) return res.status(400).end();

    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');

    const sendState = async () => {
        try {
            await bonita.login();
            // Kiểm tra đang ở task "Nhân viên phê duyệt" chưa xong
            const pending = await bonita.findTaskRobust(caseId, 'Nhan vien phe duyet');
            if (pending) {
                res.write(`data: ${JSON.stringify({ approvalPending: true })}\n\n`);
                return;
            }
            // Nếu không còn pending => check "Tạo số tài khoản"
            const createTask = await bonita.findTaskRobust(caseId, 'Tao so tai khoan');
            res.write(`data: ${JSON.stringify({
                approvalPending: false,
                createAccountReady: !!createTask,
                taskId: createTask?.id || null
            })}\n\n`);
        } catch (err) {
            res.write(`data: ${JSON.stringify({ error: err.message })}\n\n`);
        }
    };

    // Gửi lần đầu
    await sendState();

    // Lặp lại mỗi 2s (có thể giảm xuống 1s nếu cần mượt)
    const intervalId = setInterval(sendState, 2000);

    // Khi client ngắt kết nối
    req.on('close', () => clearInterval(intervalId));
});


/**
 * 5. Lấy danh sách task "Nhân viên phê duyệt" đang chờ duyệt
 */
app.get('/workflow/account/pending', async (req, res) => {
    try {
        await bonita.login();

        // Lấy tất cả human task "Nhân viên phê duyệt" đang ở trạng thái ready
        const tasks = await bonita.getHumanTasks('Nhan vien phe duyet');

        // Lấy thêm dữ liệu khách hàng (accountDataInput) theo caseId
        const results = [];
        for (const task of tasks) {
            const accountData = await bonita.getCaseVariable(task.caseId, 'accountData');
            results.push({
                taskId: task.id,
                caseId: task.caseId,
                customer: accountData ? accountData.value : null
            });
        }

        res.json(results);
    } catch (err) {
        console.error('Lỗi lấy danh sách pending:', err.message);
        res.status(500).json({ error: err.message });
    }
});
/**
 * 6. API duyệt hoặc từ chối hồ sơ trong Manual Review
 */
app.post("/workflow/account/review", async (req, res) => {
    try {
        const { taskId, caseId, status } = req.body;

        if (!taskId || !caseId || !status) {
            return res
                .status(400)
                .json({ error: "taskId, caseId, status (approved/rejected) là bắt buộc" });
        }

        // 1. Đăng nhập Bonita
        await bonita.login();

        // 2. Assign task cho user ID=1 (vd: walter.bates)
        await bonita.assignTask(taskId, 1);

        // 3. Cập nhật biến case (approvedcontract)
        const approvedValue = status === 'approved';
        console.log('Status received:', status);
        console.log('Approved value:', approvedValue);

        // Gửi giá trị approved qua payload contract input
        await bonita.executeTask(taskId, {
            approvedcontract: approvedValue
        });

        res.json({
            message: `Đã duyệt hồ sơ caseId=${caseId}, status=${status}`,
        });
    } catch (err) {
        console.error("Lỗi duyệt hồ sơ:", err.message);
        res.status(500).json({ error: err.message });
    }
});

//=========================================================================//
// ví dụ /workflow/account/next-create-account-task?caseId=3008
app.get('/workflow/account/next-create-account-task', async (req, res) => {
    try {
        const { caseId } = req.query;
        if (!caseId) return res.status(400).json({ error: 'Thiếu caseId' });

        await bonita.login();
        const task = await bonita.findTaskRobust(caseId, 'Tao so tai khoan'); // đúng tên task trong Bonita
        if (!task) return res.json({ ready: false });

        return res.json({ ready: true, taskId: task.id, caseId: task.caseId, name: task.name });
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: e.message });
    }
});

// API nhập số tài khoản vào case
// POST /workflow/account/account-number
// body:
//  - Cách 1: { taskId: "60098", accountnumber: "9704..." }  ← ƯU TIÊN
//  - Cách 2: { caseId: "3007", accountnumber: "9704...", taskName?: "Tao so tai khoan" }
app.post('/workflow/account/account-number', async (req, res) => {
    try {
        const { taskId, caseId, accountnumber, taskName = 'Tao so tai khoan' } = req.body;
        if (!accountnumber || (!taskId && !caseId))
            return res.status(400).json({ error: 'Thiếu accountnumber và taskId/caseId' });

        await bonita.login();

        // 1) Có taskId thì dùng luôn
        let task = null;
        if (taskId) {
            task = await bonita.getTaskById(taskId);
            if (!task) return res.status(404).json({ error: `Không thấy task id=${taskId}` });
        } else {
            // 2) Không có taskId -> tìm theo caseId + tên task (robust)
            task = await bonita.findTaskRobust(caseId, taskName);
            if (!task) return res.status(404).json({ error: `Không thấy task "${taskName}" (caseId=${caseId})` });
        }

        // Assign & submit contract input (key đúng là accountnumber)
        await bonita.assignTask(task.id, 1);
        await bonita.executeTask(task.id, { accountnumber });

        res.json({ message: 'Đã nhập số tài khoản', taskId: task.id, caseId: task.caseId });
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: e.message });
    }
});

//=========================================================================//
//API đổi mật khẩu
// POST /workflow/account/change-password
app.post("/workflow/account/change-password", async (req, res) => {
  const { customerId, oldPassword, newPassword } = req.body;
  const token = req.headers.authorization; // Lấy token từ Flutter truyền lên

  try {
    const response = await fetch("http://user-service:8080/api/customers/change-password", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": token || "" // Truyền tiếp token vào user-service
      },
      body: JSON.stringify({ customerId, oldPassword, newPassword })
    });

    const data = await response.json();
    res.status(response.status).json(data);
  } catch (err) {
    res.status(500).json({ error: "Lỗi server khi gọi user-service" });
  }
});

// API quên mật khẩu – có truyền token nếu có
app.post("/workflow/account/forgot-password", async (req, res) => {
    const { cccd, email, phone } = req.body;
    const token = req.headers.authorization; // Lấy token từ request gốc nếu có

    try {
        const response = await fetch("http://user-service:8080/api/customers/forgot-password", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                ...(token && { "Authorization": token }) // Chỉ thêm nếu có token
            },
            body: JSON.stringify({ cccd, email, phone })
        });

        const data = await response.json();
        res.status(response.status).json(data);
    } catch (err) {
        console.error("Lỗi gọi user-service:", err);
        res.status(500).json({ error: "Lỗi server khi gọi user-service" });
    }
});


app.listen(5053, () => {
    console.log('Workflow API chạy tại http://localhost:5053');
});
