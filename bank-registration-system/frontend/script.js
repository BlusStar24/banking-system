let currentCaseId = null;

document.getElementById('registerForm').onsubmit = async function (e) {
    e.preventDefault();

    const method = document.querySelector('input[name="method"]:checked')?.value;
    const data = {
        name: document.getElementById('name').value,
        phone: document.getElementById('phone').value,
        email: document.getElementById('email').value,
        cccd: document.getElementById('cccd').value,
        dob: document.getElementById('dob').value,
        hometown: document.getElementById('hometown').value,
        method: method  
    };

    if (!data.phone || !data.method) {
        alert('Vui lòng điền số điện thoại và chọn phương thức OTP');
        return;
    }
    if (data.method === 'email' && !data.email) {
        alert('Vui lòng điền email khi chọn phương thức email');
        return;
    }

    try {
        // Gọi API Workflow start
        const res = await fetch('http://localhost:5050/workflow/account/start', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });

        const result = await res.json();
        console.log('Workflow start result:', result);

        if (res.ok) {
            // Lưu caseId để dùng cho OTP và check status
            currentCaseId = result.caseId;
            alert('Mã OTP đã được gửi, vui lòng nhập OTP');
            document.getElementById('otpSection').style.display = 'block';
        } else {
            alert('Lỗi gửi OTP: ' + (result.error || 'Không xác định'));
        }
    } catch (error) {
        alert('Lỗi kết nối: ' + error.message);
        console.error('Error:', error);
    }
};

document.getElementById('verifyBtn').onclick = async function () {
    const code = document.getElementById('otp').value;

    if (!currentCaseId || !code) {
        alert('Thiếu caseId hoặc mã OTP');
        return;
    }

    try {
        // Gọi API Workflow OTP
        const res = await fetch('http://localhost:5050/workflow/account/otp', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ caseId: currentCaseId, otp: code })
        });

        const result = await res.json();
        console.log('Workflow OTP result:', result);

        if (res.ok) {
            alert('Xác minh OTP thành công!');
            // Check trạng thái quy trình sau khi verify OTP
            await checkStatus();
        } else {
            alert('Xác minh OTP thất bại: ' + (result.error || 'Sai OTP'));
        }

        document.getElementById('otpSection').style.display = 'none';
        document.getElementById('registerForm').reset();
        currentCaseId = null;
    } catch (error) {
        alert('Lỗi xác minh OTP: ' + error.message);
        console.error('Error:', error);
    }
};

// Hàm check trạng thái quy trình
async function checkStatus() {
    if (!currentCaseId) return;

    try {
        const res = await fetch(`http://localhost:5050/workflow/account/status/${currentCaseId}`);
        const status = await res.json();
        console.log('Process status:', status);

        alert(`Trạng thái process: ${status.state}
Task hiện tại: ${status.currentTasks.length
                ? status.currentTasks.map(t => `${t.name} (${t.state})`).join(', ')
                : 'Không còn task nào'
            }`);
    } catch (err) {
        console.error('Lỗi lấy trạng thái:', err);
    }
}
