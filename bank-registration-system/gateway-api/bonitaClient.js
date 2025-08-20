require('dotenv').config();
const fetch = require('node-fetch');

const BONITA_BASE_URL = process.env.BONITA_BASE_URL || 'http://localhost:25854/bonita';

let cookies = '';
let apiToken = '';

/**
 * 1. Login Bonita
 */
async function login(username = 'walter.bates', password = 'bpm') {
    const res = await fetch(`${BONITA_BASE_URL}/loginservice`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({ username, password })
    });

    if (!res.ok) throw new Error(`Login Bonita thất bại: ${res.status}`);

    cookies = res.headers.get('set-cookie') || '';

    // Lấy token từ Set-Cookie
    const tokenHeader = cookies.match(/X-Bonita-API-Token=([^;]+)/);
    apiToken = tokenHeader ? tokenHeader[1] : '';

    return { cookies, apiToken };
}

/**
 * 2. Lấy processId theo tên
 */
async function getProcessId(processName) {
    const res = await fetch(`${BONITA_BASE_URL}/API/bpm/process?p=0&c=1&f=name=${processName}`, {
        method: 'GET',
        headers: {
            Cookie: cookies,
            'X-Bonita-API-Token': apiToken
        }
    });
    const data = await res.json();
    if (!data.length) throw new Error(`Không tìm thấy process: ${processName}`);
    return data[0].id;
}

/**
 * 3. Start process (gửi Contract Input accountDataInput)
 */
async function startProcess(processId, contractData) {
    const res = await fetch(`${BONITA_BASE_URL}/API/bpm/process/${processId}/instantiation`, {
        method: 'POST',
        headers: {
            Cookie: cookies,
            'X-Bonita-API-Token': apiToken,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(contractData)
    });

    const text = await res.text();             // fix
    const data = text ? JSON.parse(text) : {}; // fix

    if (!res.ok) throw new Error(`Start process lỗi: ${res.status}`);
    return data;
}

/**
 * 4. Tìm task OTP trong caseId
 */
async function findTask(caseId, taskName) {
    const res = await fetch(
        `${BONITA_BASE_URL}/API/bpm/humanTask?p=0&c=20&f=state=ready&f=caseId=${caseId}`,
        {
            method: 'GET',
            headers: {
                Cookie: cookies,
                'X-Bonita-API-Token': apiToken
            }
        }
    );
    const tasks = await res.json();
    return tasks.find((t) => t.name === taskName);
}

/**
 * 5. Thực thi task OTP (gửi Contract Input otpdataInput)
 */
async function executeTask(taskId, payload) {
    // Gán task
    await fetch(`${BONITA_BASE_URL}/API/bpm/humanTask/${taskId}`, {
        method: 'PUT',
        headers: {
            Cookie: cookies,
            'X-Bonita-API-Token': apiToken,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ assigned_id: 1 })
    });

    console.log('📦 Payload OTP gửi sang Bonita:', JSON.stringify(payload, null, 2));

    // Submit task
    const res = await fetch(`${BONITA_BASE_URL}/API/bpm/userTask/${taskId}/execution`, {
        method: 'POST',
        headers: {
            Cookie: cookies,
            'X-Bonita-API-Token': apiToken,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(payload)
    });

    if (!res.ok) throw new Error(`Execute task lỗi: ${res.status}`);

    // Fix: kiểm tra nếu body rỗng thì trả về object rỗng
    const text = await res.text();
    return text ? JSON.parse(text) : {};
}


/**
 * 6. Lấy trạng thái case
 */
async function getCaseStatus(caseId) {
    const caseRes = await fetch(`${BONITA_BASE_URL}/API/bpm/case/${caseId}`, {
        method: 'GET',
        headers: {
            Cookie: cookies,
            'X-Bonita-API-Token': apiToken
        }
    });
    if (!caseRes.ok) throw new Error(`Không tìm thấy case: ${caseId}`);
    const caseData = await caseRes.json();

    const tasksRes = await fetch(`${BONITA_BASE_URL}/API/bpm/flowNode?f=caseId=${caseId}`, {
        method: 'GET',
        headers: {
            Cookie: cookies,
            'X-Bonita-API-Token': apiToken
        }
    });
    const tasks = await tasksRes.json();

    // Tổng hợp kết quả nhiều check
    const summary = {
        isBlacklisted: tasks.find((t) => t.displayName === 'Check Blacklist')?.state === 'completed',
        isSanctioned: tasks.find((t) => t.displayName === 'Check Sanction')?.state === 'completed',
        isPEP: tasks.find((t) => t.displayName === 'Check PEP')?.state === 'completed',
        creditCheckDone: tasks.find((t) => t.displayName === 'Credit Check')?.state === 'completed',
        fraudCheckDone: tasks.find((t) => t.displayName === 'Fraud Check')?.state === 'completed'
    };

    return {
        caseId,
        state: caseData.state,
        tasks: tasks.map((t) => ({
            id: t.id,
            name: t.displayName,
            state: t.state
        })),
        summary
    };
}

/**
 * Lấy danh sách human task theo tên
 */
async function getHumanTasks(taskName) {
    const res = await fetch(`${BONITA_BASE_URL}/API/bpm/humanTask?f=state=ready&f=name=${encodeURIComponent(taskName)}`, {
        method: 'GET',
        headers: {
            Cookie: cookies,
            'X-Bonita-API-Token': apiToken
        }
    });
    if (!res.ok) throw new Error(`Get human tasks lỗi: ${res.status}`);
    return await res.json();
}


/**
 * Assign task cho user
 */
async function assignTask(taskId, userId) {
    const res = await fetch(`${BONITA_BASE_URL}/API/bpm/humanTask/${taskId}`, {
        method: "PUT",
        headers: {
            Cookie: cookies,
            "X-Bonita-API-Token": apiToken,
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ assigned_id: userId }),
    });

    if (!res.ok) {
        const text = await res.text();
        throw new Error(`Assign task lỗi: ${res.status} - ${text}`);
    }
}

/**
 * Update process variable (ví dụ accountData.status)
 */
async function getCaseVariable(caseId, varName) {
    const res = await fetch(`${BONITA_BASE_URL}/API/bpm/caseVariable/${caseId}/${varName}`, {
        method: 'GET',
        headers: {
            Cookie: cookies,
            'X-Bonita-API-Token': apiToken
        }
    });

    if (res.status === 404) {
        return null; // không có biến này
    }

    if (!res.ok) {
        const text = await res.text();
        throw new Error(`Get case variable lỗi: ${res.status} - ${text}`);
    }

    return await res.json();
}

async function updateVariable(caseId, varName, value) {
    // Tự động xác định type theo giá trị
    let type = "java.lang.String";
    if (typeof value === "boolean") {
        type = "java.lang.Boolean";
    } else if (typeof value === "number") {
        type = "java.lang.Integer";
    }

    const res = await fetch(`${BONITA_BASE_URL}/API/bpm/caseVariable/${caseId}/${varName}`, {
        method: 'PUT',
        headers: {
            Cookie: cookies,
            'X-Bonita-API-Token': apiToken,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ value, type })
    });

    if (!res.ok) {
        const text = await res.text();
        throw new Error(`Update variable lỗi: ${res.status} - ${text}`);
    }
}

//==================================================================================================================================================================//
// ========================================Match task name with case-insensitive comparison=================================================================
function _norm(s = '') { return s.normalize('NFD').replace(/\p{Diacritic}/gu, '').toLowerCase().trim(); }

async function getTaskById(taskId) {
    const r = await fetch(`${BONITA_BASE_URL}/API/bpm/humanTask/${taskId}`, {
        headers: { Cookie: cookies, 'X-Bonita-API-Token': apiToken }
    });
    if (!r.ok) return null;
    return await r.json();
}

async function findTaskRobust(caseId, taskName) {
    // Ưu tiên lọc theo caseId rồi so sánh tên đã normalize
    const r1 = await fetch(`${BONITA_BASE_URL}/API/bpm/humanTask?p=0&c=100&f=state=ready&f=caseId=${caseId}`, {
        headers: { Cookie: cookies, 'X-Bonita-API-Token': apiToken }
    });
    const list1 = await r1.json();
    const target = _norm(taskName);
    let t = list1.find(x => _norm(x.name) === target || _norm(x.displayName) === target);
    if (t) return t;

    // Dự phòng: lọc theo name rồi khớp caseId
    const r2 = await fetch(`${BONITA_BASE_URL}/API/bpm/humanTask?p=0&c=100&f=state=ready&f=name=${encodeURIComponent(taskName)}`, {
        headers: { Cookie: cookies, 'X-Bonita-API-Token': apiToken }
    });
    const list2 = await r2.json();
    return list2.find(x => String(x.caseId) === String(caseId)) || null;
}

//==================================================================================================================================================================//
module.exports = {
    login,
    getProcessId,
    startProcess,
    findTask,
    executeTask,
    getCaseStatus,
    getHumanTasks,
    getCaseVariable,
    assignTask,
    updateVariable,
    getTaskById,
    findTaskRobust
};


