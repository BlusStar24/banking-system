// transferBonitaClient.js
require('dotenv').config();
const fetch = require('node-fetch');

//const BONITA_BASE_URL = process.env.BONITA_BASE_URL || 'http://host.docker.internal:25854/bonita';
const BONITA_BASE_URL = 'http://bonita:8080/bonita'; // ép cứng dùng địa chỉ container
const TRANSFER_PROCESS_NAME = process.env.TRANSFER_PROCESS_NAME || 'TransferBank';

let cookies = '';
let apiToken = '';

function _norm(s = '') {
    return s.normalize('NFD').replace(/\p{Diacritic}/gu, '').toLowerCase().trim();
}

async function login(username = process.env.BONITA_USERNAME || 'walter.bates',
    password = process.env.BONITA_PASSWORD || 'bpm') {
    const res = await fetch(`${BONITA_BASE_URL}/loginservice`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({ username, password })
    });
    if (!res.ok) throw new Error(`Login Bonita thất bại: ${res.status}`);

    cookies = res.headers.get('set-cookie') || '';
    const tokenHeader = cookies.match(/X-Bonita-API-Token=([^;]+)/);
    apiToken = tokenHeader ? tokenHeader[1] : '';
    return { cookies, apiToken };
}

async function getProcessIdByName(processName = TRANSFER_PROCESS_NAME) {
    const res = await fetch(`${BONITA_BASE_URL}/API/bpm/process?p=0&c=1&f=name=${encodeURIComponent(processName)}`, {
        headers: { Cookie: cookies, 'X-Bonita-API-Token': apiToken }
    });
    const data = await res.json();
    if (!data.length) throw new Error(`Không tìm thấy process: ${processName}`);
    return data[0].id;
}

async function startProcess(processId, payloadObj) {
    const res = await fetch(`${BONITA_BASE_URL}/API/bpm/process/${processId}/instantiation`, {
        method: 'POST',
        headers: {
            Cookie: cookies,
            'X-Bonita-API-Token': apiToken,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(payloadObj)
    });
    const text = await res.text();
    if (!res.ok) throw new Error(`Start process lỗi: ${res.status} - ${text}`);
    return text ? JSON.parse(text) : {};
}

async function startTransfer(payloadObj) {
    await login();
    const pid = await getProcessIdByName();
    return await startProcess(pid, payloadObj); // payloadObj là object contract input trực tiếp
}

async function getTaskById(taskId) {
    const res = await fetch(`${BONITA_BASE_URL}/API/bpm/humanTask/${taskId}`, {
        headers: { Cookie: cookies, 'X-Bonita-API-Token': apiToken }
    });
    if (!res.ok) return null;
    return await res.json();
}

async function findOpenTaskByName(caseId, taskName) {
    const r1 = await fetch(`${BONITA_BASE_URL}/API/bpm/humanTask?p=0&c=100&f=state=ready&f=caseId=${caseId}`, {
        headers: { Cookie: cookies, 'X-Bonita-API-Token': apiToken }
    });
    const list1 = await r1.json();
    const target = _norm(taskName);
    let t = list1.find(x => _norm(x.name) === target || _norm(x.displayName) === target);
    if (t) return t;

    const r2 = await fetch(`${BONITA_BASE_URL}/API/bpm/humanTask?p=0&c=100&f=state=ready&f=name=${encodeURIComponent(taskName)}`, {
        headers: { Cookie: cookies, 'X-Bonita-API-Token': apiToken }
    });
    const list2 = await r2.json();
    return list2.find(x => String(x.caseId) === String(caseId)) || null;
}

async function assignTask(taskId, userId = 1) {
    const r = await fetch(`${BONITA_BASE_URL}/API/bpm/humanTask/${taskId}`, {
        method: 'PUT',
        headers: {
            Cookie: cookies,
            'X-Bonita-API-Token': apiToken,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ assigned_id: userId })
    });
    if (!r.ok) throw new Error(`Assign task lỗi: ${r.status} - ${await r.text()}`);
}

async function executeTask(taskId, payloadObj) {
    const r = await fetch(`${BONITA_BASE_URL}/API/bpm/userTask/${taskId}/execution`, {
        method: 'POST',
        headers: {
            Cookie: cookies,
            'X-Bonita-API-Token': apiToken,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(payloadObj)
    });
    const text = await r.text();
    if (!r.ok) throw new Error(`Execute task lỗi: ${r.status} - ${text}`);
    return text ? JSON.parse(text) : {};
}

async function executeTaskByName(caseId, taskName, payloadObj, assignUserId = 1) {
    await login();
    const task = await findOpenTaskByName(caseId, taskName);
    if (!task) throw new Error(`Không thấy task READY "${taskName}" (caseId=${caseId})`);
    await assignTask(task.id, assignUserId);
    const res = await executeTask(task.id, payloadObj);
    return { taskId: task.id, caseId: task.caseId, execRes: res };
}

module.exports = {
    login,
    getProcessIdByName,
    startProcess,
    startTransfer,
    findOpenTaskByName,
    getTaskById,
    assignTask,
    executeTask,
    executeTaskByName
};
